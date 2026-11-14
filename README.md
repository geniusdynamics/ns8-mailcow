# ns8-mailcow

Module id: `mailcow`. [mailcow](https://mailcow.email/) (mailcow-dockerized) on NethServer 8: Postfix,
Dovecot, rspamd, SOGo, ClamAV and the mailcow web UI, in one rootless Podman pod.

**mailcow replaces the NS8 Mail app.** A node that runs mailcow does not run ns8-mail: both need the
mail ports. `configure-module` refuses to run when an ns8-mail instance is on the same node.

## Install

```bash
add-module ghcr.io/geniusdynamics/mailcow:latest 1
```

The command returns the instance id, for example `mailcow1`. Use the id NS8 returns. One instance per
node (`org.nethserver.max-per-node=1`).

## Configure

```bash
api-cli run configure-module --agent module/mailcow1 --data - <<'EOF'
{
  "host": "mail.example.org",
  "http2https": true,
  "lets_encrypt": true,
  "netfilter_mode": "external",
  "clamd_enabled": true
}
EOF
```

| Parameter | Required | Type | Description |
|---|---|---|---|
| `host` | yes | string | Mail host name (`MAILCOW_HOSTNAME`): name of the SMTP and IMAP server, of its certificate and of the web UI |
| `lets_encrypt` | yes | boolean | Request a Let's Encrypt certificate through Traefik. Postfix and Dovecot use it too |
| `http2https` | yes | boolean | Redirect HTTP to HTTPS |
| `netfilter_mode` | no | `disabled`, `external`, `rootful` | netfilter-mailcow mode, see [Brute-force protection](#brute-force-protection). Default `external`; omitted, the current value is kept |
| `clamd_enabled` | no | boolean | Run ClamAV (about 1 GB of RAM more). Default `true`; omitted, the current value is kept |

The Settings page of the app has the same fields. Point the A record of `host`, and the MX record of
the mail domains, to the node. Domains, mailboxes, aliases, DKIM keys, relay hosts (Configuration >
Routing) and spam settings are managed in the mailcow UI at `https://<host>/`; the first login is
`admin` / `moohoo`: change it at once.

`get-configuration` returns `host`, `http2https`, `lets_encrypt`, `netfilter_mode`, `clamd_enabled`,
`mail_ports` and `mailcow_release`. It never returns secrets.

## Architecture

### What ns8-mail does, and what this module does the same way

The design follows the official [ns8-mail](https://github.com/NethServer/ns8-mail) module:

| Topic | ns8-mail | ns8-mailcow |
|---|---|---|
| Rootless or rootful | rootless (no `org.nethserver.rootfull` label) | rootless |
| Ports below 1024 | containers with `--network=host`; NS8 sets `net.ipv4.ip_unprivileged_port_start=23` (core `install-core.sh`), so a rootless process binds 25 | the pod publishes 25, 465, 587, 143, 993, 110, 995 and 4190 on the node, allowed by the same sysctl. The pod keeps its own network namespace because mailcow's internal ports (Redis 6379, nginx 80, dockerapi 443...) would collide with the node |
| Node firewall | `node:fwadm`, `agent.add_public_service()` in `create-module`, `remove_public_service()` in `destroy-module` | the same, plus 4190 (ManageSieve), as mailcow-dockerized publishes it |
| Certificates | `traefik@node:fulladm`; `get-certificate` helper of the core writes the Traefik certificate of the mail host name; `certificate-changed` event reloads Postfix and Dovecot | the same: `state/ssl/{cert,key}.pem` is mounted on `/etc/ssl/mail` of Postfix, Dovecot and nginx; `events/certificate-changed` reloads them. acme-mailcow is not used |
| DNS resolver | a private unbound inside its rspamd container (port 11336), no forwarders | the unbound container of mailcow, DNS server of the whole pod |
| Smarthost and relay | relay rules of its own UI (`set-relay-configuration`); it does not consume the cluster smarthost, it provides mail to the other modules | relay hosts and sender-dependent transports of the mailcow UI |
| User domains (LDAP) | binds an NS8 user domain (`cluster:accountconsumer`) | not used: mailcow keeps its own mailboxes in MariaDB (it can use an identity provider configured in its UI) |

The module does not publish `imap`/`submission` service keys like ns8-mail: other NS8 modules
(Roundcube, WebTop) would expect the actions of ns8-mail behind them.

### The pod

All the containers run in the `mailcow` pod and share one network namespace, so they reach each other
on the loopback:

- the names of mailcow-dockerized (`redis-mailcow`, `dovecot`, `rspamd`, `phpfpm`, `nginx`,
  `dockerapi`...) resolve to `127.0.0.1`: `/etc/hosts` of the pod (`bin/create-pod`) and local records
  of unbound, because some entrypoints query DNS with `dig`;
- `IPV4_NETWORK` is `127.0.0`, so the addresses mailcow derives from it (`.248` SOGo, `.249` Redis,
  `.250` Dovecot, `.253` Postfix) are loopback addresses too;
- the containers carry the `com.docker.compose.project`/`service` labels: dockerapi finds them through
  the Podman API socket of the module user, which the UI (container status, queue, restarts) and the
  php-fpm entrypoint (database upgrade) need.

Client addresses: Postfix, Dovecot and netfilter must see the real address of every client. pasta, the
rootless network of Podman 5 (Rocky Linux 9, Debian 13), keeps it; on slirp4netns the pod uses its
`port_handler=slirp4netns`, which keeps it too (`bin/create-pod`). Postfix trusts only the pod
(`mynetworks = 127.0.0.0/8 [::1]/128`): mailcow's `mynetworks_style = subnet` would trust the whole
subnet of the node, which the pod copies from the host.

### DNS: unbound in the pod

rspamd and Postfix query DNS blocklists (Spamhaus and others). Those refuse queries that come through
public resolvers, so mailcow needs its own recursive resolver. The DNS apps of the NS8 catalog
([index](https://nethserver.github.io/ns8-apps/#/apps?q=dns), `catalog.json`) do not fit:

- [ns8-dnsmasq](https://github.com/NethServer/ns8-dnsmasq) (official, rootful): DNS and DHCP for the
  LAN, it forwards to the upstream resolvers of the node;
- Pi-hole and AdGuard Home (community): filtering forwarders, to public resolvers by default;
- PowerDNS (community): authoritative only; DNS helper: records through provider APIs; ddclient:
  dynamic DNS.

None is a recursive resolver of its own, and depending on another app would make the mail flow depend
on its configuration. ns8-mail made the same choice (unbound inside its rspamd container). So the
unbound container of mailcow runs in the pod, with the upstream `unbound.conf` (mounted as a file, so
`unbound-anchor` writes `trusted-key.key` in `/etc/unbound`), and the pod uses it as DNS server
(`podman pod create --dns=127.0.0.1`). It resolves from the root servers, with DNSSEC.

### Configuration files

`build-images.sh` downloads the pinned mailcow-dockerized release (`MAILCOW_RELEASE`) and adds
`data/conf`, `data/web`, `data/assets` and `data/hooks` to the image as `imageroot/mailcow-dist`, with
the database schema version of its `docker-compose.yml`. The images are the tags of that release, in
the Renovate format.

`bin/sync-mailcow-data` copies them to `state/mailcow` at each `configure-module` and update: files of
the release are replaced, files the containers or the admin created (`extra.cf`, `extra.conf`,
`vars.local.inc.php`, generated SQL maps...) are kept, the customization points (rspamd custom maps,
SOGo logos, global sieve filters) are created once. It then applies the NS8 changes: Postfix
`mynetworks`, the unbound records, and two hooks (`data/hooks`): SOGo single sign-on from 127.0.0.1 for
Dovecot, and the copy of the Postfix log to the node journal (see CrowdSec below).

The settings of mailcow.conf are in `state/mailcow.env`, the MariaDB ones in `state/mysql.env`, the
secrets in `state/secrets.env`: all mode 0600.

### Periodic jobs

ofelia is replaced by systemd timers: `mailcow-cron-{minutely,5min,20min,30min,daily}.timer` run
`bin/mailcow-cron`, which runs the jobs of the ofelia labels of `docker-compose.yml` with `podman exec`
(SOGo sessions and alarms, imapsync, quarantine notifications, maildir GC, SA rules...).

Not used: acme-mailcow (Traefik certificates), ofelia (timers), watchdog (systemd restarts the
units; its checks expect the addresses of the docker network).

## Brute-force protection

### netfilter_mode

| Mode | netfilter-mailcow | Firewall |
|---|---|---|
| `external` (default) | runs in the pod with "Manage Fail2Ban externally" (`manage_external=1` in the `F2B_OPTIONS` Redis key, set by `bin/netfilter-prepare`): it counts the failures and keeps the ban list | no rule is changed. The ban list is served at `https://<host>/f2b-banlist.php?id=<token>`; the token is shown in the mailcow UI (Configuration > Configuration & Details > Fail2ban), which can also renew it. A firewall or CrowdSec can poll it |
| `rootful` | runs in the pod and applies the bans itself, with `--cap-add=NET_ADMIN --cap-add=NET_RAW` and `DISABLE_NETFILTER_ISOLATION_RULE=y` | its `MAILCOW` chain in the network namespace of the pod (nftables): a banned client cannot reach the mail ports |
| `disabled` | does not run | none from mailcow: use CrowdSec |

The other containers only publish failures to the `F2B_CHANNEL` of Redis and read the ban state, so
they work in every mode.

**Why `rootful` does not act on the node firewall.** The planned design was a root-owned
netfilter-mailcow unit with `--network=host`, next to the rootless pod. NS8 cannot split a module like
that: a module is rootless or rootful as a whole, chosen at install time by the
`org.nethserver.rootfull` image label (the node `add-module` action creates either a Unix user with
systemd user units or units in `/etc/systemd/system`). The node agent offers no action that installs a
system unit for a rootless module (its actions: firewall services, zones and rich rules, ports, TUN
devices). A rootless container has no `NET_ADMIN` on the node network namespace, even with
`--network=host`. Making the whole module rootful would run every mail container as root, unlike
ns8-mail, and could not be a setting.

So netfilter-mailcow stays rootless and uses `NET_ADMIN` where a rootless container has it: the network
namespace of the pod, owned by the user namespace of the module. Every mail connection enters that
namespace with its real client address, so the bans are effective for all the mailcow ports.
`bin/netfilter-entrypoint.sh` creates the filter tables netfilter needs there and forces its nftables
backend. Web logins come through Traefik from 127.0.0.1, so a ban does not block the web UI of a
banned client; node-wide bans are the job of CrowdSec.

### CrowdSec

NS8 [CrowdSec](https://github.com/NethServer/ns8-crowdsec) (rootful, one per node) reads the whole node
journal (`journalctl` acquisition of `_TRANSPORT=journal`, `syslog` and `stdout`, type `syslog`) and
bans on the node firewall with its bouncer. It installs the `crowdsecurity/postfix` and
`crowdsecurity/dovecot` collections by default. Its custom parsers are files of its own image
(`imageroot/tainted`): there is no directory, event or action through which another module can add
some, and a rootless module cannot write into its root-owned configuration.

What works without any step:

- Postfix copies its log to the node `/dev/log` (hook `00-ns8-hostlog.sh`), so the journal has
  `postfix/smtpd[PID]: ...` lines like ns8-mail. The stock `crowdsecurity/postfix` collection then bans
  SMTP AUTH brute force, non-SMTP commands, relay and HELO abuse.

What needs one command: mailcow checks the IMAP, POP3, ManageSieve and SMTP AUTH logins in php-fpm
(`MAILCOWAUTH: Login failed ...`), and logs SOGo and UI login failures. Every container logs to the
journal with its unit name as identifier (`--log-opt=tag=%N`). The module ships a parser and a
scenario for these lines: `imageroot/crowdsec/mailcow-logs.yaml` (`geniusdynamics/mailcow-logs`) and
`mailcow-bf.yaml` (`geniusdynamics/mailcow-bf`, 5 failures, leak 1 minute, like NS8's WebTop
scenario). Install them as root on the node, once CrowdSec runs (replace the instance ids):

```bash
install -m 644 /home/mailcow1/.config/crowdsec/mailcow-logs.yaml /var/lib/nethserver/crowdsec1/state/crowdsec_config/parsers/s01-parse/
install -m 644 /home/mailcow1/.config/crowdsec/mailcow-bf.yaml /var/lib/nethserver/crowdsec1/state/crowdsec_config/scenarios/
systemctl reload crowdsec1
runagent -m crowdsec1 cscli scenarios inspect geniusdynamics/mailcow-bf
```

Repeat it after a mailcow update that changes the files. CrowdSec whitelists private addresses.

Without CrowdSec nothing bans on the node firewall: brute-force protection is netfilter-mailcow
(`external` keeps only the list, `rootful` bans in the pod), and the lines stay in the journal.

## Network and access

- Mail ports 25, 465, 587, 143, 993, 110, 995 and 4190 on all the addresses of the node, opened on the
  node firewall.
- 1 TCP port (`TCP_PORT`) on 127.0.0.1 for nginx; Traefik terminates TLS for the web UI, SOGo,
  autodiscover/autoconfig, MTA-STS and the ban list.
- Authorizations: `traefik@node:fulladm` (route and certificate), `node:fwadm` (mail ports).
- Rootless; minimum core 3.20.1 (the `get-certificate` helper).

## Images

Pinned in `build-images.sh`, mailcow-dockerized 2026-11:

| Image | Version |
|---|---|
| `docker.io/library/mariadb` | `10.11.19` |
| `docker.io/library/redis` | `7.4.12-alpine` |
| `docker.io/library/memcached` | `1.6.45-alpine` |
| `ghcr.io/mailcow/unbound` | `1.26.2-1` |
| `ghcr.io/mailcow/clamd` | `1.4.6-1` |
| `ghcr.io/mailcow/rspamd` | `4.2.3-1` |
| `ghcr.io/mailcow/phpfpm` | `8.2.35-2` |
| `ghcr.io/mailcow/sogo` | `5.12.13-1` |
| `ghcr.io/mailcow/dovecot` | `2.3.21.1-4` |
| `ghcr.io/mailcow/postfix` | `3.10.12-1` |
| `ghcr.io/mailcow/postfix-tlspol` | `1.14.0` |
| `ghcr.io/mailcow/nginx` | `1.30.6-2` |
| `ghcr.io/mailcow/netfilter` | `1.67` |
| `ghcr.io/mailcow/dockerapi` | `2.15` |
| `ghcr.io/mailcow/olefy` | `1.16` |

## Services

- `mailcow.service`: the pod
- `mysql-mailcow-app`, `redis-mailcow-app`, `memcached-mailcow-app`, `unbound-mailcow-app`, `dockerapi`,
  `php-fpm-mailcow-app`, `sogo-mailcow-app`, `dovecot-mailcow-app`, `postfix-tlspol-mailcow-app`,
  `postfix-mailcow-app`, `olefy-mailcow-app`, `rspamd-mailcow-app`, `nginx-mailcow-app`
- optional: `clamd-mailcow-app` (`clamd_enabled`), `netfilter-mailcow-app` (`netfilter_mode`)
- timers: `mailcow-cron-*.timer`

A unit reports "started" only when its service answers (`bin/wait-ready`): MariaDB and Redis ping,
unbound answers, PHP-FPM listens (after the database upgrade), SOGo, Dovecot, Postfix and rspamd
listen, nginx answers HTTP. The first start initializes the database and takes a few minutes.

Logs: `journalctl SYSLOG_IDENTIFIER=postfix-mailcow-app` (any unit name), and `postfix/smtpd` & co.
for the Postfix copy.

## Backup

`imageroot/etc/state-include.conf`: the database dump (`bin/module-dump-state`), `state/secrets.env`,
`state/mailcow/conf` (customizations), and the volumes `vmail-vol-1`, `crypt-vol-1` (mail_crypt keys),
`redis-vol` (DKIM keys and settings, saved first), `rspamd-vol-1`, `postfix-vol-1` and
`sogo-userdata-backup-vol-1`. `vmail-vol-1` can be placed on an additional disk at install time.

Restore loads the dump into a new MariaDB volume, then calls `configure-module` with the settings of
the backup. Restore and clone never turn Let's Encrypt on: the DNS may not point to the new node yet.

## Get the configuration

```bash
api-cli run get-configuration --agent module/mailcow1
```

## Update and uninstall

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/geniusdynamics/mailcow:latest","instances":["mailcow1"],"force":true}'
remove-module --no-preserve mailcow1
```

The update copies the configuration files of the new release, writes the env files and restarts the
pod. Instances of the web-only releases get their mail services and ports then.

## Testing

Continuous integration:

- `Publish images` builds the module image on every push.
- `Test module` installs the image on QEMU NS8 nodes (Rocky Linux 9, Debian 13) and runs
  `tests/mailcow.robot`: configuration read-back, web UI through Traefik, mail ports on the node
  firewall, SMTP banners on 25, 465 and 587, IMAP 143 and 993, POP3 and ManageSieve, failed logins in
  the node journal, the CrowdSec rules (`cscli explain` in NS8 CrowdSec), and the three netfilter
  modes. The workflow runs from the default branch: its `vm_mem` and `timeout_minutes` take effect
  once merged to `main`.

Run it locally with the NS8 standard infrastructure described in the [ns8-github-actions README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Upstream

Application documentation: https://docs.mailcow.email/

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
