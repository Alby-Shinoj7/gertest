FROM debian:12.2-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg wget lsb-release ca-certificates \
    && echo "deb http://repo.mysql.com/apt/debian/ bookworm mysql-8.0" > /etc/apt/sources.list.d/mysql.list \
    && wget -qO - https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 | gpg --dearmor > /etc/apt/trusted.gpg.d/mysql.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends mysql-server pwgen gosu \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/var/lib/mysql"]

EXPOSE 3306

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]
