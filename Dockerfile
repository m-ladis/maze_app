FROM nginx:alpine

# Ako želiš lokalni deploy, koristi ovo
# COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf



