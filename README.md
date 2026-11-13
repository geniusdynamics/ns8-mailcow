# ns8-mailcow

Module id: `mailcow`. Images are pinned in `build-images.sh` and updated through reviewed changes.

## Install

```bash
add-module ghcr.io/geniusdynamics/mailcow:latest 1
```

The command returns the instance id, for example `mailcow1`. Use the id NS8 returns.

## Configure

```bash
api-cli run configure-module --agent module/mailcow1 --data - <<'EOF'
{
  "host": "mailcow.example.org",
  "http2https": true,
  "lets_encrypt": false
}
EOF
```

| Parameter | Required | Type | Description |
|---|---|---|---|
| `host` | yes | string | Host name for the application, like 'mailcow.domain.org' |
| `lets_encrypt` | yes | boolean | Request a valid Let's Encrypt certificate. |
| `http2https` | yes | boolean | Redirect all the HTTP requests to HTTPS |

## Configuration output

`get-configuration` returns: `host`, `lets_encrypt`, `http2https`.

## Images

| Image | Version |
|---|---|
| `docker.io/library/mariadb` | `10.11.19` |
| `docker.io/library/redis` | `7.4.12-alpine` |
| `ghcr.io/mailcow/unbound` | `1.24` |
| `ghcr.io/mailcow/clamd` | `1.71` |
| `ghcr.io/mailcow/rspamd` | `3.14.2` |
| `ghcr.io/mailcow/phpfpm` | `8.2.29-1` |
| `ghcr.io/mailcow/sogo` | `5.12.4-1` |
| `ghcr.io/mailcow/dovecot` | `2.3.21.1-1` |
| `ghcr.io/mailcow/postfix` | `3.7.11-1` |
| `ghcr.io/mailcow/postfix-tlspol` | `1.8.22` |
| `docker.io/library/memcached` | `1.6.45-alpine` |
| `ghcr.io/mailcow/nginx` | `1.05` |
| `ghcr.io/mailcow/acme` | `1.95` |
| `ghcr.io/mailcow/netfilter` | `1.63` |
| `ghcr.io/mailcow/watchdog` | `2.09` |
| `ghcr.io/mailcow/dockerapi` | `2.11` |
| `ghcr.io/mailcow/olefy` | `1.15` |
| `docker.io/mcuadros/ofelia` | `v3.0.8` |

## Network and access

- Reserves 1 TCP port(s) on the node. The web application is published through Traefik on the configured host name.
- Runs rootless.
- Declares these NS8 authorizations: `traefik@node:routeadm`.

## Backup

The following paths are included in the NS8 backup (`imageroot/etc/state-include.conf`):

- `state/unbound-mailcow.env`
- `volumes/hooks-unbound`
- `volumes/conf-unbound-unboundconf`
- `state/clamd-mailcow.env`
- `volumes/conf-clamav-`
- `volumes/clamd-db-vol-1`
- `state/sogo-mailcow.env`
- `volumes/hooks-sogo`
- `volumes/conf-sogo-`
- `volumes/web-inc-initdbincphp`
- `volumes/conf-sogo-custom-faviconico`
- `volumes/conf-sogo-custom-shortlogosvg`
- `volumes/conf-sogo-custom-fulllogosvg`
- `volumes/conf-sogo-custom-fulllogopng`
- `volumes/conf-sogo-custom-themejs`
- `volumes/conf-sogo-custom-sogojs`
- `volumes/mysql-socket-vol-1`
- `volumes/sogo-web-vol-1`
- `volumes/sogo-userdata-backup-vol-1`
- `state/dovecot-mailcow.env`
- `volumes/hooks-dovecot`
- `volumes/conf-dovecot`
- `volumes/assets-ssl`
- `volumes/conf-sogo-`
- `volumes/phpfpm-sogo-sso-`
- `volumes/vmail-vol-1`
- `volumes/vmail-index-vol-1`
- `volumes/crypt-vol-1`
- `volumes/rspamd-custom-`
- `volumes/assets-templates`
- `volumes/rspamd-vol-1`
- `volumes/mysql-socket-vol-1`
- `state/postfix-tlspol-mailcow.env`
- `volumes/postfix-tlspol-vol-1`
- `state/nginx-mailcow.env`
- `volumes/data-web`
- `volumes/conf-rspamd-dynmaps`
- `volumes/assets-ssl-`
- `volumes/conf-nginx-`
- `volumes/conf-rspamd-metaexporter`
- `volumes/dovecot-auth-mailcowauthphp`
- `volumes/web-inc-functionsincphp`
- `volumes/web-inc-functionsauthincphp`
- `volumes/web-inc-sessionsincphp`
- `volumes/sogo-web-vol-1`
- `state/dockerapi-mailcow.env`
- `volumes/run-dockersock`
- `state/olefy-mailcow.env`
- `state/mysql-mailcow.env`
- `volumes/mysql-vol-1`
- `volumes/mysql-socket-vol-1`
- `volumes/conf-mysql-`
- `state/postfix-mailcow.env`
- `volumes/hooks-postfix`
- `volumes/conf-postfix`
- `volumes/assets-ssl`
- `volumes/postfix-vol-1`
- `volumes/crypt-vol-1`
- `volumes/rspamd-vol-1`
- `volumes/mysql-socket-vol-1`
- `state/memcached-mailcow.env`
- `state/acme-mailcow.env`
- `volumes/web-well-known-acme-challenge`
- `volumes/assets-ssl`
- `volumes/assets-ssl-example`
- `volumes/mysql-socket-vol-1`
- `state/netfilter-mailcow.env`
- `volumes/lib-modules`
- `state/watchdog-mailcow.env`
- `volumes/rspamd-vol-1`
- `volumes/mysql-socket-vol-1`
- `volumes/postfix-vol-1`
- `volumes/assets-ssl`
- `state/redis-mailcow.env`
- `volumes/redis-vol-1`
- `volumes/conf-redis-redis-confsh`
- `state/rspamd-mailcow.env`
- `volumes/hooks-rspamd`
- `volumes/rspamd-custom-`
- `volumes/rspamd-overrided-`
- `volumes/rspamd-locald-`
- `volumes/rspamd-pluginsd-`
- `volumes/rspamd-lua-`
- `volumes/conf-rspamd-rspamdconflocal`
- `volumes/conf-rspamd-rspamdconfoverride`
- `volumes/rspamd-vol-1`
- `state/ofelia-mailcow.env`
- `volumes/run-dockersock`
- `state/php-fpm-mailcow.env`
- `volumes/hooks-phpfpm`
- `volumes/data-web`
- `volumes/conf-rspamd-dynmaps`
- `volumes/rspamd-custom-`
- `volumes/dovecot-auth-mailcowauthphp`
- `volumes/web-inc-functionsincphp`
- `volumes/web-inc-functionsauthincphp`
- `volumes/web-inc-sessionsincphp`
- `volumes/web-inc-functionsmailboxincphp`
- `volumes/web-inc-functionsratelimitincphp`
- `volumes/web-inc-functionsaclincphp`
- `volumes/rspamd-vol-1`
- `volumes/mysql-socket-vol-1`
- `volumes/conf-sogo-`
- `volumes/conf-rspamd-metaexporter`
- `volumes/conf-phpfpm-crons`
- `volumes/phpfpm-sogo-sso-`
- `volumes/phpfpm-php-fpmd-poolsconf`
- `volumes/phpfpm-php-confd-opcache-recommendedini`
- `volumes/phpfpm-php-confd-uploadini`
- `volumes/phpfpm-php-confd-otherini`
- `volumes/conf-dovecot-globalsievebefore`
- `volumes/conf-dovecot-globalsieveafter`
- `volumes/assets-templates`
- `volumes/conf-nginx-`

## Services

- `acme-mailcow-app.service`
- `clamd-mailcow-app.service`
- `dockerapi.service`
- `dovecot-mailcow-app.service`
- `mailcow.service`
- `memcached-mailcow-app.service`
- `mysql-mailcow-app.service`
- `netfilter-mailcow-app.service`
- `nginx-mailcow-app.service`
- `ofelia-mailcow-app.service`
- `olefy-mailcow-app.service`
- `php-fpm-mailcow-app.service`
- `postfix-mailcow-app.service`
- `postfix-tlspol-mailcow-app.service`
- `redis-mailcow-app.service`
- `rspamd-mailcow-app.service`
- `sogo-mailcow-app.service`
- `unbound-mailcow-app.service`
- `watchdog-mailcow-app.service`

## Get the configuration

```bash
api-cli run get-configuration --agent module/mailcow1
```

## Update and uninstall

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/geniusdynamics/mailcow:latest","instances":["mailcow1"],"force":true}'
remove-module --no-preserve mailcow1
```

## Testing

Continuous integration:

- `Publish images` builds the module image on every push.
- `Test module` installs the image on a QEMU NS8 node and runs the Robot Framework suite in `tests/`. It runs after `Publish images` succeeds on `dev` and on `main`.
- `Build API JSON Schema docs` and the security scan run alongside.

The suite installs the module, configures a host name, checks that the web application answers through Traefik, takes UI screenshots and removes the module.

Run it locally with the NS8 standard infrastructure described in the [ns8-github-actions README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Open items

Found by the NS8 module standards check. These must be resolved before a stable release:

- The module description is still the template text: write a description of at least 60 characters in ui/public/metadata.json
- metadata: documentation_url is a placeholder
- metadata: categories empty (use standard categories)
- metadata: description.en needs >= 60 real chars (+ it translation)
- ACME_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- CLAMD_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- DOCKERAPI_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- DOVECOT_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- MEMCACHED_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- NETFILTER_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- NGINX_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- OFELIA_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- OLEFY_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- PHPFPM_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- POSTFIX_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- POSTFIX_TLSPOL_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- REDIS_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- RSPAMD_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- SOGO_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- UNBOUND_IMAGE is used by the module but no image in the label provides it: leftover from the template?
- WATCHDOG_IMAGE is used by the module but no image in the label provides it: leftover from the template?

## Upstream

Application documentation: https://docs.mailcow.com/

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
