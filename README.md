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

- Reserves 1 TCP port on the node, published on port 80 (nginx) of the pod. Traefik terminates TLS and publishes the mailcow UI on the configured host name.
- Secrets (database, Redis, API keys) are in `state/*.env` files with mode 0600.
- Runs rootless.
- Declares these NS8 authorizations: `traefik@node:routeadm`.

## Backup

The NS8 backup (`imageroot/etc/state-include.conf`) holds `state/mysql-mailcow.sql`, the dump of the mailcow database written by `bin/module-dump-state`.

## Services

Running: the web UI stack.

- `mailcow.service`: the pod
- `mysql-mailcow-app.service`
- `redis-mailcow-app.service`
- `memcached-mailcow-app.service`
- `dockerapi.service`: the UI refuses to load without it ("Connection to dockerapi container failed"). It reads the Podman API socket of the module user.
- `php-fpm-mailcow-app.service`
- `nginx-mailcow-app.service`

Present but not started: `acme`, `clamd`, `dovecot`, `netfilter`, `ofelia`, `olefy`, `postfix`, `postfix-tlspol`, `rspamd`, `sogo`, `unbound`, `watchdog`. See "Mail services" below.

## Mail services

The module runs the mailcow **web UI only**: admins can log in and manage the mailcow database, but no mail is sent or received. To run the mail services in rootless Podman, the module still needs:

- public ports 25, 465, 587, 143, 993, 110, 995 and 4190, opened with `org.nethserver.tcp-ports-demand` port mapping and `node:fwadm`. A rootless pod cannot bind these ports on the host. ns8-mail already owns them on a standard NS8 node.
- `netfilter-mailcow`, which edits the host firewall (iptables/nftables) with `NET_ADMIN` and host networking. That is impossible rootless; on NS8 the firewall belongs to the node agent.
- `unbound-mailcow` with its configuration from `data/conf/unbound` (today it fails: `unable to open /etc/unbound/trusted-key.key`), and the other containers using it as their DNS server.
- the configuration directories of dovecot, postfix, rspamd and SOGo mounted from `data/conf`, ofelia's job configuration (today: `open /etc/ofelia/config.ini: no such file or directory`), and certificates shared with postfix and dovecot.

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

## Upstream

Application documentation: https://docs.mailcow.com/

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
