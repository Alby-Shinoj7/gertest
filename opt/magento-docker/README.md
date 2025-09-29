# Magento 2 Debian 12.2 Container Stack

This repository provides a fully containerized Magento 2 platform where every image is built from `debian:12.2-slim`. Services include Nginx (backend), PHP-FPM 8.3, MySQL 8.0, OpenSearch 2.x, Redis 7, Varnish 7, and an Nginx TLS proxy. phpMyAdmin is delivered through the backend Nginx on a dedicated port and proxied via TLS at `pma.mgt.com`.

---

## Project Tree

```
/opt/magento-docker
├── certs/
│   └── .gitkeep
├── docker-compose.yml
├── mysql/
│   ├── Dockerfile
│   └── docker-entrypoint.sh
├── nginx-backend/
│   ├── Dockerfile
│   └── sites.conf
├── nginx-ssl/
│   ├── Dockerfile
│   └── ssl.conf
├── opensearch/
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   └── opensearch.yml
├── php-fpm/
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   └── php.ini
├── redis/
│   ├── Dockerfile
│   └── redis.conf
├── varnish/
│   ├── Dockerfile
│   └── default.vcl
└── README.md
```

---

## Preflight Checklist (Run Before Deployment)

- [ ] **Hardware** – ≥4 vCPU, 12 GB RAM, 60 GB free disk. Enable ≥4 GB swap for Composer stability.
- [ ] **Host OS** – Debian 12 patched (`sudo apt update && sudo apt upgrade -y`).
- [ ] **Ports Free** – 80, 443, 8080, 8081, 3306, 6379, 6081, 9200, 9600 unused.
- [ ] **Firewall** – Allow inbound 80/443 and ensure Docker bridge traffic permitted.
- [ ] **Hosts file (workstation)** – Add `192.168.1.14 test.mgt.com pma.mgt.com` (or `127.0.0.1` when testing locally).
- [ ] **Kernel sysctl** – `sudo sysctl -w vm.max_map_count=262144` and persist via `/etc/sysctl.d/99-opensearch.conf`.
- [ ] **Swap** – Optional but recommended: `sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`.

---

## Step-by-Step Implementation Guide

### 1. Install Docker Engine + Compose Plugin (Debian Host)

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

Log out/in to activate group membership.

### 2. Obtain the Project

```bash
sudo mkdir -p /opt
sudo chown $USER:$USER /opt
cd /opt
git clone <this-repo-url> magento-docker
cd magento-docker/opt/magento-docker
```

### 3. Prepare Environment Variables (`.env`)

```bash
cat <<'ENV' > .env
MYSQL_ROOT_PASSWORD=ChangeMeRoot!234
MYSQL_DATABASE=magento
MYSQL_USER=magento
MYSQL_PASSWORD=ChangeMeApp!234
ENV
```

Adjust passwords before production use.

### 4. Generate Self-Signed Certificate (SAN: test.mgt.com, pma.mgt.com)

```bash
cd /opt/magento-docker/certs
openssl req -x509 -nodes -days 825 \
  -newkey rsa:4096 \
  -keyout test.mgt.com.key \
  -out test.mgt.com.crt \
  -subj "/C=US/ST=Denial/L=Springfield/O=Magento Dev/OU=DevOps/CN=test.mgt.com" \
  -addext "subjectAltName=DNS:test.mgt.com,DNS:pma.mgt.com"
chmod 600 test.mgt.com.key
```

### 5. Build and Launch Containers

```bash
cd /opt/magento-docker
docker compose --env-file .env build
sudo sysctl -w vm.max_map_count=262144
sudo tee /etc/sysctl.d/99-opensearch.conf <<<"vm.max_map_count=262144"
docker compose --env-file .env up -d
docker compose ps
```

Tail critical logs while services initialize:

```bash
docker compose logs -f --tail=100 mysql opensearch
```

### 6. Fetch Magento via Composer

```bash
docker compose exec php-fpm bash
su - test-ssh
composer config -g http-basic.repo.magento.com <PUBLIC_KEY> <PRIVATE_KEY>
cd /var/www/html
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.6-p4 .
exit
exit
```

If Composer is killed (OOM), ensure swap is enabled then re-run – command is idempotent. For offline mirrors, point Composer to a local artifact repository.

### 7. Run `bin/magento setup:install`

```bash
docker compose exec php-fpm bash
su - test-ssh
cd /var/www/html
bin/magento setup:install \
  --base-url=https://test.mgt.com/ \
  --backend-frontname=admin \
  --db-host=mysql \
  --db-name=${MYSQL_DATABASE} \
  --db-user=${MYSQL_USER} \
  --db-password=${MYSQL_PASSWORD} \
  --admin-firstname=Store \
  --admin-lastname=Admin \
  --admin-email=admin@example.com \
  --admin-user=AdminUser99 \
  --admin-password='ChangeAdmin!234' \
  --language=en_US \
  --currency=USD \
  --timezone=UTC \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=opensearch \
  --opensearch-port=9200 \
  --opensearch-index-prefix=magento \
  --opensearch-enable-auth=0
exit
exit
```

Re-run only after dropping the database (`bin/magento setup:uninstall`).

### 8. Configure Redis (cache + session)

```bash
docker compose exec php-fpm bash
su - test-ssh
cd /var/www/html
bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=redis --cache-backend-redis-db=0
bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=redis --page-cache-redis-db=1
bin/magento setup:config:set --session-save=redis --session-save-redis-host=redis --session-save-redis-port=6379 --session-save-redis-db=2
exit
exit
```

### 9. Force HTTPS Base URLs

```bash
docker compose exec php-fpm bash
su - test-ssh
cd /var/www/html
bin/magento setup:store-config:set --base-url="https://test.mgt.com/"
bin/magento setup:store-config:set --base-url-secure="https://test.mgt.com/"
exit
exit
```

### 10. Enable Varnish Full-Page Cache

```bash
docker compose exec php-fpm bash
su - test-ssh
cd /var/www/html
bin/magento setup:config:set --http-cache-hosts=varnish:6081
bin/magento cache:enable full_page
bin/magento varnish:vcl:generate \
  --export-version=6 \
  --output-file=/tmp/varnish.vcl \
  --backend-host=nginx-backend \
  --backend-port=8080
exit
exit
```

Copy the generated VCL and restart Varnish (safe to repeat):

```bash
cat /tmp/varnish.vcl | docker exec -i magento-varnish tee /etc/varnish/default.vcl >/dev/null
docker compose restart varnish
```

### 11. Compile, Deploy, Warm, Index, Install Cron

```bash
docker compose exec php-fpm bash
su - test-ssh
cd /var/www/html
bin/magento maintenance:enable
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento setup:static-content:deploy -f
bin/magento maintenance:disable
bin/magento cache:flush
bin/magento cache:clean
bin/magento cache:warmup
bin/magento indexer:reindex
bin/magento cron:install
exit
exit
```

Verify cron schedule inside the container if required: `docker compose exec php-fpm crontab -l`.

### 12. Install phpMyAdmin (served on backend port 8081)

```bash
docker compose exec php-fpm bash
su - test-ssh
cd /var/www/html
curl -fsSL https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz | tar -xz
rm -rf phpmyadmin
mv phpMyAdmin-5.2.1-all-languages phpmyadmin
chmod -R 775 phpmyadmin
chown -R test-ssh:clp phpmyadmin
exit
exit
```

### 13. Update Hosts File & Access URLs

```
192.168.1.14 test.mgt.com pma.mgt.com
```

- Storefront/Admin: https://test.mgt.com, https://test.mgt.com/admin
- phpMyAdmin: https://pma.mgt.com

---

## Post-Deployment Verification Commands

```bash
cd /opt/magento-docker

# Container state
docker compose ps

# TLS + Varnish headers
curl -kI https://test.mgt.com --resolve test.mgt.com:443:192.168.1.14
curl -kI https://test.mgt.com --resolve test.mgt.com:443:192.168.1.14 | grep -E 'Via|X-Varnish'

# Magento health
docker compose exec php-fpm bin/magento cron:run --group=default
docker compose exec php-fpm bin/magento app:config:dump scopes themes system

# OpenSearch
docker compose exec opensearch curl -s localhost:9200/_cluster/health

# MySQL
MYSQL_PWD=${MYSQL_ROOT_PASSWORD} docker compose exec mysql mysqladmin ping -h localhost -p${MYSQL_ROOT_PASSWORD}

# Log spot checks
docker compose logs --tail=50 varnish nginx-ssl nginx-backend php-fpm
```

Expect `Via` and `X-Varnish` headers to confirm Varnish is serving responses.

---

## Export & Backup Procedures

### Export Custom Images

```bash
cd /opt/magento-docker
docker save magento-mysql:latest -o mysql-image.tar
docker save magento-php-fpm:latest -o php-fpm-image.tar
docker save magento-nginx-backend:latest -o nginx-backend-image.tar
docker save magento-nginx-ssl:latest -o nginx-ssl-image.tar
docker save magento-varnish:latest -o varnish-image.tar
docker save magento-redis:latest -o redis-image.tar
docker save magento-opensearch:latest -o opensearch-image.tar
```

### Backup Volumes (idempotent)

```bash
mkdir -p backups
for vol in mysql-data opensearch-data redis-data magento-app; do
  docker run --rm -v ${vol}:/volume -v $(pwd)/backups:/backup debian:12.2-slim \
    tar czf /backup/${vol}-$(date +%F).tar.gz -C /volume .
done
```

### Restore Example

```bash
for archive in backups/*.tar.gz; do
  vol=$(basename "$archive" | cut -d'-' -f1-2 | sed 's/-[0-9].*//')
  docker volume create $vol
  docker run --rm -v ${vol}:/volume -v $(pwd)/backups:/backup debian:12.2-slim \
    sh -c "cd /volume && tar xzf /backup/$(basename $archive)"
done
```

---

## Roll-Forward / Roll-Back Procedures

- **Roll-forward:**
  ```bash
  cd /opt/magento-docker
  docker compose build --no-cache
  docker compose up -d --force-recreate
  ```
- **Roll-back:**
  ```bash
  cd /opt/magento-docker
  docker compose down
  # Restore previously saved volume tarballs & image tar files (see backup section)
  docker load -i <image-tar>
  docker compose up -d
  ```

Maintain dated backups to align images and volumes for consistent rollback points.

---

## Troubleshooting Guide

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| 502 Bad Gateway from TLS proxy | PHP-FPM still starting or crashed | `docker compose logs php-fpm`; rerun Magento setup, then `docker compose restart php-fpm`. |
| OpenSearch refuses to start | `vm.max_map_count` too low | `sudo sysctl -w vm.max_map_count=262144` and restart `magento-opensearch`. |
| Mixed-content warnings in browser | Base URLs not HTTPS | Re-run Step 9 to enforce secure URLs and flush cache. |
| Composer killed/OOM | Insufficient RAM | Add swap (see Preflight) and rerun Composer. |
| Redirect loop after enabling Varnish | Magento cache misconfiguration | Flush caches (`bin/magento cache:flush`), verify `app/etc/env.php` for correct `http_cache_hosts`. |

---

## Final Readiness Checklist (“All Green”)

- [ ] Docker services healthy (`docker compose ps` shows `Up` with passing healthchecks).
- [ ] TLS certificate/key present in `certs/` with restricted permissions.
- [ ] Magento storefront/admin reachable via HTTPS and presents `Via` + `X-Varnish` headers.
- [ ] phpMyAdmin accessible at `https://pma.mgt.com` through TLS proxy.
- [ ] Redis and OpenSearch enabled in `app/etc/env.php`.
- [ ] Backups of images and volumes completed.
- [ ] Roll-forward/roll-back playbooks validated.
- [ ] Monitoring commands scripted/available (curl, bin/magento checks, log tails).

Tick all boxes before declaring the environment deployable.
