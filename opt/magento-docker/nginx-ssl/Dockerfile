FROM debian:12.2-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx openssl \
    && rm -rf /var/lib/apt/lists/*

RUN rm /etc/nginx/sites-enabled/default

COPY ssl.conf /etc/nginx/conf.d/ssl.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
