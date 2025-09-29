FROM debian:12.2-slim

ENV DEBIAN_FRONTEND=noninteractive \
    OPENSEARCH_VERSION=2.11.1 \
    OPENSEARCH_HOME=/usr/share/opensearch

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg openjdk-17-jdk-headless unzip tar bash \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --home ${OPENSEARCH_HOME} --shell /usr/sbin/nologin opensearch \
    && mkdir -p ${OPENSEARCH_HOME}

RUN curl -fsSL https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VERSION}/opensearch-${OPENSEARCH_VERSION}-linux-x64.tar.gz | tar -xz -C /tmp \
    && mv /tmp/opensearch-${OPENSEARCH_VERSION} ${OPENSEARCH_HOME} \
    && chown -R opensearch:opensearch ${OPENSEARCH_HOME}

COPY opensearch.yml ${OPENSEARCH_HOME}/config/opensearch.yml
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chown opensearch:opensearch ${OPENSEARCH_HOME}/config/opensearch.yml \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9200 9600

USER opensearch

WORKDIR ${OPENSEARCH_HOME}

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["opensearch"]
