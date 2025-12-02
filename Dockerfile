FROM nginx:alpine

# Kopiraj Flutter Web build u Nginx
COPY build/web /usr/share/nginx/html

# Kopiraj custom nginx config za SPA fallback
COPY nginx.conf /etc/nginx/conf.d/default.conf


