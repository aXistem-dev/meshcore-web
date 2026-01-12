#!/bin/bash

# Script to automatically check for new MeshCore web app versions and update the local directory
# Usage: ./update-from-source.sh
# 
# This script:
# 1. Checks version.json for current version
# 2. Checks the server for the latest version
# 3. If newer version exists, downloads and extracts it to the local directory
# 4. Updates README.md with the new version
# 
# NOTE: This script only updates files locally. It does NOT:
# - Stage or commit changes

set -uo pipefail

BASE_URL="https://files.liamcottle.net/MeshCore"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/meshcore-web-update"
ZIP_FILENAME=""  # Global variable to store the zip filename

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

# Function to get current version from version.json
get_current_version() {
    if [ -f "version.json" ]; then
        # Extract version from version.json (format: "version":"1.34.0")
        local version=$(grep -oE '"version":\s*"[0-9]+\.[0-9]+\.[0-9]+"' version.json 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$version" ]; then
            echo "v${version}"
            return 0
        fi
    fi
    return 1
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
    
    # Store zip filename in global variable
    ZIP_FILENAME="$zip_file"
    
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

# Function to update README.md with version
update_readme_version() {
    local version=$1
    local zip_file=$2
    
    if [ ! -f "README.md" ]; then
        print_warn "README.md not found, skipping version update"
        return 0
    fi
    
    print_info "Updating version in README.md to ${version}..."
    
    # Verify README.md exists and has content
    if [ ! -s "README.md" ]; then
        print_error "README.md is missing or empty"
        return 1
    fi
    
    # Check if "Current version:" line exists
    if ! grep -q "Current version:" README.md; then
        print_warn "Could not find 'Current version:' line in README.md"
        return 1
    fi
    
    # Get build number from version.json if available
    local build_number=""
    if [ -f "version.json" ]; then
        build_number=$(grep -oE '"build_number":\s*"[0-9]+"' version.json 2>/dev/null | grep -oE '[0-9]+' | head -1)
    fi
    
    # Construct the URL
    local zip_url="https://files.liamcottle.net/MeshCore/${version}/${zip_file}"
    
    # Build the new version line
    local new_line="Current version: [**${version}**](${zip_url})"
    if [ -n "$build_number" ]; then
        new_line="${new_line} ([build ${build_number}](./version.json))"
    fi
    
    # Use a temporary file for cross-platform compatibility
    local temp_file=$(mktemp)
    
    # Replace the entire "Current version:" line with the new version line
    # This works regardless of the old format (with or without link, with or without build number)
    if command -v gsed >/dev/null 2>&1; then
        # Use GNU sed if available (gsed on macOS)
        gsed "s|.*Current version:.*|${new_line}|" README.md > "$temp_file"
    else
        # Use standard sed (works on both GNU and BSD sed)
        sed "s|.*Current version:.*|${new_line}|" README.md > "$temp_file"
    fi
    
    # Verify the temp file was created and has content
    if [ ! -s "$temp_file" ]; then
        print_error "Failed to create updated README.md - temp file is empty"
        rm -f "$temp_file"
        return 1
    fi
    
    # Replace the original file
    mv "$temp_file" README.md
    
    # Verify the update was successful - use fgrep for literal string matching
    if grep -Fq "[**${version}**]" README.md; then
        print_info "Successfully updated README.md to ${version}"
        return 0
    else
        print_error "README.md update failed - version ${version} not found in file after update"
        print_info "Current version line in README.md:"
        grep "Current version:" README.md || true
        return 1
    fi
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
    
    # Get current version from version.json
    local current_version=$(get_current_version)
    if [ -z "$current_version" ]; then
        print_error "Could not read version from version.json"
        exit 1
    fi
    
    print_info "Current local version: ${current_version}"
    
    # Get all available versions from server
    print_info "Checking for available versions on server..."
    local available_versions=$(get_available_versions)
    
    if [ -z "$available_versions" ]; then
        print_error "Could not fetch available versions from server"
        exit 1
    fi
    
    # Get the latest version from server
    local latest_version=$(echo "$available_versions" | sort -V | tail -1)
    
    if [ -z "$latest_version" ]; then
        print_error "Could not determine latest version from server"
        exit 1
    fi
    
    print_info "Latest version available on server: ${latest_version}"
    
    # Check if we already have the latest version
    if [ "$current_version" = "$latest_version" ]; then
        print_info "Latest version ${latest_version} is already installed. Nothing to update."
        exit 0
    fi
    
    # Process the latest version
    print_info "Updating to version ${latest_version}..."
    
    # Download and extract
    KEEP_TEMP=1
    local source_dir=""
    # Capture only stdout (the path), let stderr (info messages) go to console
    if ! source_dir=$(download_and_extract "${latest_version}" 2>/dev/null); then
        print_error "Failed to download and extract version ${latest_version}"
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
    
    # Copy new files from extracted zip to local directory (overwrites existing files)
    # Note: README.md is persistent and not in the zip, so it won't be overwritten
    print_info "Copying files to local directory (overwriting existing files)..."
    if [ ! -d "${source_dir}" ]; then
        print_error "Source directory does not exist: ${source_dir}"
        cleanup
        exit 1
    fi
    
    # Copy all files from extracted zip to current directory, overwriting existing files
    cp -rf "${source_dir}"/* .
    
    # Update version in README.md (use zip filename from global variable or fetch it)
    local zip_file="${ZIP_FILENAME}"
    if [ -z "$zip_file" ]; then
        # Fallback: try to get zip filename from version directory
        local version_url="${BASE_URL}/${latest_version}/"
        zip_file=$(curl -s "${version_url}" | grep -oE 'MeshCore-[^"]+-web\.zip' | head -1)
    fi
    if [ -z "$zip_file" ]; then
        print_warn "Could not determine zip filename, using version only in README"
        zip_file="MeshCore-${latest_version}-web.zip"
    fi
    if ! update_readme_version "${latest_version}" "${zip_file}"; then
        print_warn "Failed to update README.md with version ${latest_version}, but files were updated successfully"
    fi
    
    # Cleanup after successful update
    cleanup
    
    print_info "Update complete! Local directory has been updated to version ${latest_version}."
}

# Run main function
main "$@"
