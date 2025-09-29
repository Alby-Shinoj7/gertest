FROM debian:12.2-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends redis-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/redis \
    && chown redis:redis /var/lib/redis

COPY redis.conf /etc/redis/redis.conf

VOLUME ["/var/lib/redis"]

EXPOSE 6379

USER redis

CMD ["redis-server", "/etc/redis/redis.conf"]
