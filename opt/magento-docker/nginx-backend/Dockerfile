FROM debian:12.2-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx curl \
    && rm -rf /var/lib/apt/lists/*

RUN rm /etc/nginx/sites-enabled/default

COPY sites.conf /etc/nginx/conf.d/sites.conf

EXPOSE 8080 8081

CMD ["nginx", "-g", "daemon off;"]
