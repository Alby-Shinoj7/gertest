#!/bin/bash
set -euo pipefail

if [ "$1" = "opensearch" ]; then
  export OPENSEARCH_PATH_CONF="${OPENSEARCH_HOME}/config"
  exec ${OPENSEARCH_HOME}/bin/opensearch
fi

exec "$@"
