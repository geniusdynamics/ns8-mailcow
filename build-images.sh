#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e

# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/geniusdynamics}"
# Configure the image name
reponame="mailcow"
# Node.js 25+ no longer ships Corepack, install it from npm
# renovate: datasource=npm packageName=corepack
corepack_version=0.36.0
# mailcow-dockerized release: the configuration files (data/conf, data/web,
# data/assets, data/hooks) are vendored into the module image from it, and the
# images below are the tags of that same release.
# renovate: datasource=github-tags packageName=mailcow/mailcow-dockerized
MAILCOW_RELEASE=2026-11
# renovate: datasource=docker packageName=docker.io/library/mariadb
MARIADB_VERSION=10.11.19
# renovate: datasource=docker packageName=docker.io/library/redis
REDIS_VERSION=7.4.12-alpine
# renovate: datasource=docker packageName=docker.io/library/memcached
MEMCACHED_VERSION=1.6.45-alpine
# renovate: datasource=docker packageName=ghcr.io/mailcow/unbound
UNBOUND_VERSION=1.26.2-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/clamd
CLAMD_VERSION=1.4.6-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/rspamd
RSPAMD_VERSION=4.2.3-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/phpfpm
PHPFPM_VERSION=8.2.35-2
# renovate: datasource=docker packageName=ghcr.io/mailcow/sogo
SOGO_VERSION=5.12.13-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/dovecot
DOVECOT_VERSION=2.3.21.1-4
# renovate: datasource=docker packageName=ghcr.io/mailcow/postfix
POSTFIX_VERSION=3.10.12-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/postfix-tlspol
POSTFIX_TLSPOL_VERSION=1.14.0
# renovate: datasource=docker packageName=ghcr.io/mailcow/nginx
NGINX_VERSION=1.30.6-2
# renovate: datasource=docker packageName=ghcr.io/mailcow/netfilter
NETFILTER_VERSION=1.67
# renovate: datasource=docker packageName=ghcr.io/mailcow/dockerapi
DOCKERAPI_VERSION=2.15
# renovate: datasource=docker packageName=ghcr.io/mailcow/olefy
OLEFY_VERSION=1.16

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-mailcow container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-mailcow; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-mailcow -v "${PWD}:/usr/src:Z" docker.io/library/node:26.13.0-slim
    buildah run nodebuilder-mailcow sh -c "npm install -g corepack@${corepack_version} && corepack enable"
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-mailcow \
    sh -c "yarn install && yarn build"

echo "Vendor the mailcow-dockerized ${MAILCOW_RELEASE} configuration..."
distdir=$(mktemp -d)
trap 'rm -rf "${distdir}"' EXIT
curl -fsSL "https://github.com/mailcow/mailcow-dockerized/archive/refs/tags/${MAILCOW_RELEASE}.tar.gz" \
    | tar -xz -C "${distdir}" --strip-components=1 --wildcards \
        '*/data/conf' '*/data/web' '*/data/assets' '*/data/hooks' '*/docker-compose.yml'
mkdir -p "${distdir}/out/mailcow-dist"
mv "${distdir}"/data/{conf,web,assets,hooks} "${distdir}/out/mailcow-dist/"
echo "${MAILCOW_RELEASE}" > "${distdir}/out/mailcow-dist/RELEASE"
# The database schema version of the release (x-db-version), read by php-fpm,
# SOGo and Dovecot from the DB_VERSION variable
db_version=$(sed -n 's/^x-db-version:.*DB_VERSION=\([0-9_]*\).*/\1/p' "${distdir}/docker-compose.yml")
test -n "${db_version}"
echo "${db_version}" > "${distdir}/out/mailcow-dist/DB_VERSION"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" "${distdir}/out" /imageroot
buildah add "${container}" ui/dist /ui
# Rootless, like ns8-mail: NS8 lets rootless containers bind ports from 23
# (net.ipv4.ip_unprivileged_port_start), so the pod publishes the mail ports.
# One TCP port: the web UI (nginx) behind Traefik, published on loopback.
# traefik fulladm: routes and the certificate of the mail host name.
# node fwadm: open the mail ports on the node firewall.
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@node:fulladm node:fwadm" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.max-per-node=1" \
    --label="org.nethserver.min-core=3.20.1" \
    --label="org.nethserver.volumes=vmail-vol-1" \
    --label="org.nethserver.images=docker.io/library/mariadb:${MARIADB_VERSION} docker.io/library/redis:${REDIS_VERSION} docker.io/library/memcached:${MEMCACHED_VERSION} ghcr.io/mailcow/unbound:${UNBOUND_VERSION} ghcr.io/mailcow/clamd:${CLAMD_VERSION} ghcr.io/mailcow/rspamd:${RSPAMD_VERSION} ghcr.io/mailcow/phpfpm:${PHPFPM_VERSION} ghcr.io/mailcow/sogo:${SOGO_VERSION} ghcr.io/mailcow/dovecot:${DOVECOT_VERSION} ghcr.io/mailcow/postfix:${POSTFIX_VERSION} ghcr.io/mailcow/postfix-tlspol:${POSTFIX_TLSPOL_VERSION} ghcr.io/mailcow/nginx:${NGINX_VERSION} ghcr.io/mailcow/netfilter:${NETFILTER_VERSION} ghcr.io/mailcow/dockerapi:${DOCKERAPI_VERSION} ghcr.io/mailcow/olefy:${OLEFY_VERSION}" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github.
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
