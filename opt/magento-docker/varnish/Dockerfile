FROM debian:12.2-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends varnish \
    && rm -rf /var/lib/apt/lists/*

COPY default.vcl /etc/varnish/default.vcl

EXPOSE 6081

CMD ["varnishd", "-F", "-f", "/etc/varnish/default.vcl", "-s", "malloc,256m"]
