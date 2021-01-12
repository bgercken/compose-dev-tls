#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DOCKER_COMPOSE_FILE="docker-compose.yml"
DOCKER_TEMPLATE_FILE="template-docker-compose.yml"
TRAEFIK_COMPOSE_FILE="traefik-compose.yml"
TRAEFIK_TEMPLATE_FILE="template-traefik-compose.yml"


# Creates a self-signed wildcard cert for local test and dev

# EXAMPLE: ./cert.sh something.com

# three files are created: 
# something.com.key - Secret key good for proxy configs
# something.com.crt - Public cert good for proxy configs
# something.com.pem - Combo of those two good for browser/OS import

DOMAIN_NAME=$1

openssl req \
  -newkey rsa:2048 \
  -x509 \
  -nodes \
  -keyout "$DOMAIN_NAME.key" \
  -new \
  -out "$DOMAIN_NAME.crt" \
  -subj "/CN=*.$DOMAIN_NAME" \
  -reqexts SAN \
  -extensions SAN \
  -config <(cat /etc/ssl/openssl.cnf \
  <(printf "[SAN]\nsubjectAltName=DNS:*.%s, DNS:%s" "$DOMAIN_NAME" "$DOMAIN_NAME")) \
  -sha256 \
  -days 3650

cat "$DOMAIN_NAME.crt" "$DOMAIN_NAME.key" > "$DOMAIN_NAME.pem"

# Update compose file(s) (if needed).

if [[ ! -f $DOCKER_COMPOSE_FILE ]]; then
  cat $DOCKER_TEMPLATE_FILE | sed 's/_DOMAIN_NAME_/'${DOMAIN_NAME}'/g' > $DOCKER_COMPOSE_FILE
fi

if [[ ! -f $TRAEFIK_COMPOSE_FILE ]]; then
  cat $TRAEFIK_TEMPLATE_FILE | sed 's/_DOMAIN_NAME_/'${DOMAIN_NAME}'/g' > $TRAEFIK_COMPOSE_FILE
fi
