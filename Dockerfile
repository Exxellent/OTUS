FROM alpine:latest

RUN apk add --no-cache nginx

RUN mkdir -p /var/www/html /var/log/nginx /run/nginx

COPY nginx.conf /etc/nginx/nginx.conf

COPY index.html /var/www/html/index.html

RUN chown -R nginx:nginx /var/www/html /var/log/nginx /run/nginx && \
    nginx -t

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
