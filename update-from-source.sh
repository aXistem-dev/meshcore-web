#!/bin/bash

# Script to automatically check for new MeshCore web app versions and update the repository
# Usage: ./update-from-source.sh
# 
# This script:
# 1. Checks the server for available versions
# 2. Finds the latest version that we don't have yet
# 3. Downloads and extracts it
# 4. Creates a new version branch (v*.*.*)
# 5. Updates the version in README.md
# 6. Pushes to the version branch
# 7. Updates main branch with the same version

set -uo pipefail

BASE_URL="https://files.liamcottle.net/MeshCore"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/meshcore-web-update"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to get all version directories from the server
get_available_versions() {
    print_info "Fetching available versions from ${BASE_URL}/..."
    curl -s "${BASE_URL}/" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+/' | sed 's/\///' | sort -V
}

# Function to get the latest version
get_latest_version() {
    get_available_versions | tail -1
}

# Function to get all existing version branches (local and remote)
get_existing_branches() {
    git branch -a | grep -E 'remotes/origin/v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/remotes\/origin\///' | sed 's/^[[:space:]]*//' | sort -V
}

# Function to check if version branch exists
branch_exists() {
    local version=$1
    git branch -a | grep -q "remotes/origin/${version}$" || git branch | grep -q "^  ${version}$"
}

# Function to download and extract web.zip
download_and_extract() {
    local version=$1
    local version_url="${BASE_URL}/${version}/"
    
    print_info "Fetching file list from ${version_url}..."
    
    # Find the web.zip file
    local zip_file=$(curl -s "${version_url}" | grep -oE 'MeshCore-[^"]+-web\.zip' | head -1)
    
    if [ -z "$zip_file" ]; then
        print_error "Could not find web.zip file in ${version_url}"
        return 1
    fi
    
    local zip_url="${version_url}${zip_file}"
    print_info "Found zip file: ${zip_file}"
    print_info "Downloading from ${zip_url}..."
    
    # Create temp directory
    mkdir -p "${TEMP_DIR}"
    cd "${TEMP_DIR}"
    
    # Download the zip file
    curl -L -o "${zip_file}" "${zip_url}"
    
    if [ ! -f "${zip_file}" ]; then
        print_error "Failed to download ${zip_file}"
        return 1
    fi
    
    print_info "Extracting ${zip_file}..."
    
    # Extract zip file
    if ! unzip -q "${zip_file}" -d extracted; then
        print_error "Failed to extract ${zip_file}"
        return 1
    fi
    
    # Find the web directory inside
    if [ -d "extracted/web" ]; then
        print_info "Found web directory in zip file" >&2
        echo "${TEMP_DIR}/extracted/web"
        return 0
    else
        print_error "Could not find 'web' directory in extracted zip file" >&2
        print_info "Contents of extracted directory:" >&2
        ls -la extracted/ 2>/dev/null || true >&2
        return 1
    fi
}

# Function to save consistent files to temp location
save_consistent_files() {
    local temp_dir=$1
    
    print_info "Saving consistent files (Docker, scripts, README) to temporary location..."
    
    # List of files that should be consistent across all branches
    CONSISTENT_FILES=(
        "Dockerfile"
        "docker-compose.yml"
        ".dockerignore"
        "README-Docker.md"
        "README.md"
        "update-from-source.sh"
    )
    
    mkdir -p "${temp_dir}/consistent_files"
    
    # Save each file if it exists
    for file in "${CONSISTENT_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_info "  Saving ${file}..."
            cp "$file" "${temp_dir}/consistent_files/" 2>/dev/null || true
        elif git show "main:${file}" >/dev/null 2>&1; then
            print_info "  Saving ${file} from main branch..."
            git show "main:${file}" > "${temp_dir}/consistent_files/${file}" 2>/dev/null || true
        fi
    done
    
    # Save GitHub workflows directory (especially docker-publish.yml)
    if [ -d ".github/workflows" ]; then
        print_info "  Saving .github/workflows (including docker-publish.yml)..."
        mkdir -p "${temp_dir}/consistent_files/.github/workflows"
        cp -r ".github/workflows"/* "${temp_dir}/consistent_files/.github/workflows/" 2>/dev/null || true
    elif git ls-tree -r --name-only main | grep -q "^\.github/workflows/"; then
        print_info "  Saving .github/workflows from main branch..."
        mkdir -p "${temp_dir}/consistent_files/.github/workflows"
        git checkout main -- .github/workflows/ 2>/dev/null || true
        cp -r ".github/workflows"/* "${temp_dir}/consistent_files/.github/workflows/" 2>/dev/null || true
        git checkout - 2>/dev/null || true  # Restore previous branch
    fi
}

# Function to restore consistent files
restore_consistent_files() {
    local temp_dir=$1
    
    print_info "Restoring consistent files (Docker, scripts, README, workflows)..."
    
    if [ ! -d "${temp_dir}/consistent_files" ]; then
        print_warn "No consistent files to restore"
        return 0
    fi
    
    # Restore all saved files (excluding .github directory for now)
    if [ -d "${temp_dir}/consistent_files" ]; then
        # Copy files but exclude .github directory
        find "${temp_dir}/consistent_files" -mindepth 1 -maxdepth 1 ! -name '.github' -exec cp -r {} . 2>/dev/null \; || true
        
        # Handle .github/workflows specially
        if [ -d "${temp_dir}/consistent_files/.github/workflows" ]; then
            mkdir -p ".github/workflows"
            cp -r "${temp_dir}/consistent_files/.github/workflows"/* .github/workflows/ 2>/dev/null || true
        fi
    fi
}

# Function to update README.md with version
update_readme_version() {
    local version=$1
    
    if [ ! -f "README.md" ]; then
        print_warn "README.md not found, skipping version update"
        return 0
    fi
    
    print_info "Updating version in README.md to ${version}..."
    
    # Use a temporary file for cross-platform compatibility (works on both GNU and BSD sed)
    local temp_file=$(mktemp)
    
    # Update version line (look for "Current version: **vX.Y.Z**")
    if grep -q "Current version:" README.md; then
        sed "s/Current version: \*\*v[0-9]\+\.[0-9]\+\.[0-9]\+\*\*/Current version: **${version}**/" README.md > "$temp_file"
        mv "$temp_file" README.md
    fi
    
    # Also update the latest web version link if it exists
    if grep -q "Latest web version" README.md; then
        sed "s|Latest web version (v[0-9]\+\.[0-9]\+\.[0-9]\+):|Latest web version (${version}):|" README.md > "$temp_file"
        mv "$temp_file" README.md
    fi
    
    rm -f "$temp_file"
}

# Function to update repository with new version
update_repository() {
    local version=$1
    local source_dir=$2
    
    cd "${REPO_DIR}"
    
    # Save consistent files BEFORE cleaning (from current branch or main)
    local consistent_files_dir="${TEMP_DIR}/consistent_${version}"
    save_consistent_files "${consistent_files_dir}"
    
    print_info "Creating new branch ${version} from main..."
    git checkout main || { print_error "Failed to checkout main branch"; return 1; }
    git pull origin main || { print_error "Failed to pull from origin/main"; return 1; }
    git checkout -b "${version}" || { print_error "Failed to create new branch ${version}"; return 1; }
    
    # Remove all existing files except .git and .github
    print_info "Cleaning repository (keeping .git and .github)..."
    find . -mindepth 1 -maxdepth 1 \
        ! -name '.git' \
        ! -name '.github' \
        -exec rm -rf {} +
    
    # Copy new files from extracted zip
    print_info "Copying new files from ${source_dir}..."
    if [ ! -d "${source_dir}" ]; then
        print_error "Source directory does not exist: ${source_dir}"
        return 1
    fi
    cp -r "${source_dir}"/* .
    
    # Restore consistent files (Docker, scripts, README, workflows)
    restore_consistent_files "${consistent_files_dir}"
    
    # Update version in README.md
    update_readme_version "${version}"
    
    # Stage all changes
    git add -A
    
    # Commit changes with a single commit message
    print_info "Committing changes to ${version} branch..."
    git commit -m "Update to ${version} from source files"
    
    # Push version branch to remote
    print_info "Pushing to origin/${version}..."
    git push origin "${version}" || { print_error "Failed to push to origin/${version}"; return 1; }
    
    print_info "Successfully created and pushed ${version} branch!"
    
    # Now update main branch by merging the version branch (this keeps them in sync)
    print_info "Updating main branch by merging ${version} branch..."
    git checkout main || { print_error "Failed to checkout main branch"; return 1; }
    
    # Reset main to exactly match the version branch (this avoids the "1 ahead, 1 behind" issue)
    # This ensures main and version branch have the exact same commit history and content
    print_info "Resetting main to match ${version} branch exactly..."
    git reset --hard "${version}" || { print_error "Failed to reset main to ${version}"; return 1; }
    
    # Push main branch (force push needed since we reset)
    print_info "Pushing to origin/main (force push required)..."
    git push origin main --force-with-lease || { print_error "Failed to push to origin/main"; return 1; }
    
    print_info "Successfully updated main branch to ${version}!"
}

# Function to cleanup temp files
cleanup() {
    if [ -d "${TEMP_DIR}" ] && [ -z "${KEEP_TEMP:-}" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "${TEMP_DIR}"
    fi
}

# Main execution
main() {
    # Trap to cleanup on exit
    trap cleanup EXIT
    
    print_info "Starting MeshCore web app update check..."
    
    cd "${REPO_DIR}"
    
    # Fetch latest from remote to get all branches
    print_info "Fetching latest branches from remote..."
    git fetch origin --prune
    
    # Get all available versions from server
    print_info "Checking for available versions on server..."
    local available_versions=$(get_available_versions)
    
    if [ -z "$available_versions" ]; then
        print_error "Could not fetch available versions from server"
        exit 1
    fi
    
    # Get the latest version from server (not the latest we don't have, but the actual latest)
    local latest_version=$(echo "$available_versions" | sort -V | tail -1)
    
    if [ -z "$latest_version" ]; then
        print_error "Could not determine latest version from server"
        exit 1
    fi
    
    print_info "Latest version available on server: ${latest_version}"
    
    # Get existing version branches
    local existing_branches=$(get_existing_branches)
    
    if [ -n "$existing_branches" ]; then
        print_info "Existing version branches:"
        echo "$existing_branches" | tail -5 | sed 's/^/  /' >&2
    else
        print_info "No existing version branches found"
    fi
    
    # Check if we already have the latest version
    if branch_exists "$latest_version"; then
        print_info "Latest version ${latest_version} is already in the repository. Nothing to update."
        exit 0
    fi
    
    # Process the latest version
    local version_to_process="$latest_version"
    print_info "Latest version ${version_to_process} is not in repository - will process it"
    
    # Download and extract (disable cleanup during this process)
    KEEP_TEMP=1
    local source_dir=""
    # Capture only stdout (the path), let stderr (info messages) go to console
    if ! source_dir=$(download_and_extract "${version_to_process}" 2>/dev/null); then
        print_error "Failed to download and extract version ${version_to_process}"
        KEEP_TEMP=""
        cleanup
        exit 1
    fi
    KEEP_TEMP=""
    
    # Filter out any info messages that might have been captured
    source_dir=$(echo "$source_dir" | grep -E "^/tmp/meshcore-web-update" | head -1)
    
    if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
        print_error "Source directory invalid: '${source_dir}'"
        cleanup
        exit 1
    fi
    
    print_info "Source directory confirmed: ${source_dir}"
    
    # Update repository (creates version branch and updates main)
    if ! update_repository "${version_to_process}" "${source_dir}"; then
        print_error "Failed to update repository for version ${version_to_process}"
        cleanup
        exit 1
    fi
    
    # Cleanup after successful update
    cleanup
    
    print_info "Update complete! Version ${version_to_process} has been added to both ${version_to_process} branch and main branch."
}

# Run main function
main "$@"
