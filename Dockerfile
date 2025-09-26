# Use lightweight Nginx image
FROM nginx:alpine

# Copy all website files into Nginx default folder
COPY . /usr/share/nginx/html
