FROM nginx:alpine

# Kopiraj build koji će se napraviti u workflow-u
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf



