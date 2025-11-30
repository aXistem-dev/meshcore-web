# Use nginx to serve the static Flutter web app
FROM nginx:alpine

# Copy all static files to nginx html directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx (using default nginx configuration)
CMD ["nginx", "-g", "daemon off;"]

