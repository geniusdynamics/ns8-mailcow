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
# renovate: datasource=docker packageName=docker.io/library/mariadb
MARIADB_VERSION=10.11.19
# renovate: datasource=docker packageName=docker.io/library/redis
REDIS_VERSION=7.4.12-alpine
# renovate: datasource=docker packageName=ghcr.io/mailcow/unbound
UNBOUND_VERSION=1.24
# renovate: datasource=docker packageName=ghcr.io/mailcow/clamd
CLAMD_VERSION=1.71
# renovate: datasource=docker packageName=ghcr.io/mailcow/rspamd
RSPAMD_VERSION=3.14.2
# renovate: datasource=docker packageName=ghcr.io/mailcow/phpfpm
PHPFPM_VERSION=8.2.29-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/sogo
SOGO_VERSION=5.12.4-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/dovecot
DOVECOT_VERSION=2.3.21.1-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/postfix
POSTFIX_VERSION=3.7.11-1
# renovate: datasource=docker packageName=ghcr.io/mailcow/postfix-tlspol
POSTFIX_TLSPOL_VERSION=1.8.22
# renovate: datasource=docker packageName=docker.io/library/memcached
MEMCACHED_VERSION=1.6.45-alpine
# renovate: datasource=docker packageName=ghcr.io/mailcow/nginx
NGINX_VERSION=1.05
# renovate: datasource=docker packageName=ghcr.io/mailcow/acme
ACME_VERSION=1.95
# renovate: datasource=docker packageName=ghcr.io/mailcow/netfilter
NETFILTER_VERSION=1.63
# renovate: datasource=docker packageName=ghcr.io/mailcow/watchdog
WATCHDOG_VERSION=2.09
# renovate: datasource=docker packageName=ghcr.io/mailcow/dockerapi
DOCKERAPI_VERSION=2.11
# renovate: datasource=docker packageName=ghcr.io/mailcow/olefy
OLEFY_VERSION=1.15
# renovate: datasource=docker packageName=docker.io/mcuadros/ofelia
OFELIA_VERSION=v3.0.8

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

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
# Select you image(s) with the label org.nethserver.images
# ghcr.io/xxxxx is the GitHub container registry or your own registry or docker.io for Docker Hub
# The image tag is set to latest by default, but can be overridden with the IMAGETAG environment variable
# --label="org.nethserver.images=docker.io/mariadb:10.11.5 docker.io/roundcube/roundcubemail:1.6.4-apache"
# rootfull=0 === rootless container
# tcp-ports-demand=1 number of tcp Port to reserve , 1 is the minimum, can be udp or tcp
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@node:routeadm" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.min-core=3.0.0" \
    --label="org.nethserver.images=docker.io/library/mariadb:${MARIADB_VERSION} docker.io/library/redis:${REDIS_VERSION} ghcr.io/mailcow/unbound:${UNBOUND_VERSION} ghcr.io/mailcow/clamd:${CLAMD_VERSION} ghcr.io/mailcow/rspamd:${RSPAMD_VERSION} ghcr.io/mailcow/phpfpm:${PHPFPM_VERSION} ghcr.io/mailcow/sogo:${SOGO_VERSION} ghcr.io/mailcow/dovecot:${DOVECOT_VERSION} ghcr.io/mailcow/postfix:${POSTFIX_VERSION} ghcr.io/mailcow/postfix-tlspol:${POSTFIX_TLSPOL_VERSION} docker.io/library/memcached:${MEMCACHED_VERSION} ghcr.io/mailcow/nginx:${NGINX_VERSION} ghcr.io/mailcow/acme:${ACME_VERSION} ghcr.io/mailcow/netfilter:${NETFILTER_VERSION} ghcr.io/mailcow/watchdog:${WATCHDOG_VERSION} ghcr.io/mailcow/dockerapi:${DOCKERAPI_VERSION} ghcr.io/mailcow/olefy:${OLEFY_VERSION} docker.io/mcuadros/ofelia:${OFELIA_VERSION}" \
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
