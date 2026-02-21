# ns8-mailcow

Mail server module for [NethServer 8](https://github.com/NethServer/ns8-core) based on [mailcow-dockerized](https://mailcow.email/).

## Install

Instantiate the module with:

    add-module ghcr.io/geniusdynamics/mailcow:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "mailcow1", "image_name": "mailcow", "image_url": "ghcr.io/geniusdynamics/mailcow:latest"}

## Configure

Launch `configure-module`, by setting the following parameters:

- `host`: a fully qualified domain name for the application
- `http2https`: enable or disable HTTP to HTTPS redirection (true/false)
- `lets_encrypt`: enable or disable Let's Encrypt certificate (true/false)

Example:

```
api-cli run configure-module --agent module/mailcow1 --data - <<EOF
{
  "host": "mailcow.domain.com",
  "http2https": true,
  "lets_encrypt": true
}
EOF
```

The above command will:

- start and configure the mailcow instance
- configure a virtual host for traefik to access the instance

## Advanced Settings

The module supports extensive advanced configuration options accessible through the web UI:

### Time Settings
- Timezone (TZ)

### Network Settings
- IPv4 Network (default: 172.22.1)
- IPv6 Network (default: fd4d:6169:6c63:6f77::/64)
- Enable IPv6

### Service Skipping
- Skip SOGo (webmail)
- Skip ClamAV (antivirus)
- Skip Rspamd (spam filter)
- Skip Let's Encrypt
- Skip Full-Text Search (FTS)
- Skip OLEFY (Office document scanning)

### Ports Configuration
- HTTP Port (default: 80)
- HTTPS Port (default: 443)
- SMTP Port (default: 25)
- SMTPS Port (default: 465)
- Submission Port (default: 587)
- IMAP Port (default: 143)
- IMAPS Port (default: 993)
- POP Port (default: 110)
- POPS Port (default: 995)
- Sieve Port (default: 4190)

### Security Settings
- Password Scheme (BLF-CRYPT, ARGON2, SHA512, SHA256, MD5)
- Master Account
- Allow Admin Email Login
- ACL Anyone

### Logging
- Log Lines
- Developer Mode

### SOGo Settings
- SOGo Session Expiry (minutes)

### Dovecot Settings
- Maildir Garbage Collection Time
- Maildir Subfolders
- FTS Processes
- FTS Heap Size

### ACME Settings
- Additional SAN
- Let's Encrypt Staging
- Skip IP Check
- Only Mailcow Hostname
- Directory URL

### Netfilter Settings
- Disable Isolation Rule
- Mailcow Replica IP

## Exposed Ports

The following ports are exposed on 127.0.0.1 for mail services:

| Service | Port |
|---------|------|
| HTTP (web UI) | 80 |
| HTTPS (web UI) | 443 |
| SMTP | 25 |
| SMTPS | 465 |
| Submission | 587 |
| IMAP | 143 |
| IMAPS | 993 |
| POP3 | 110 |
| POP3S | 995 |
| Sieve | 4190 |

The web UI is accessible via Traefik using the configured hostname. Mail services are exposed directly on localhost for external mail server communication.

## Get the configuration

You can retrieve the configuration with:

```
api-cli run get-configuration --agent module/mailcow1
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve mailcow1

## Smarthost setting discovery

Some configuration settings, like the smarthost setup, are not part of the
`configure-module` action input: they are discovered by looking at some
Redis keys. To ensure the module is always up-to-date with the
centralized [smarthost
setup](https://nethserver.github.io/ns8-core/core/smarthost/) every time
mailcow starts, the command `bin/discover-smarthost` runs and refreshes
the `state/smarthost.env` file with fresh values from Redis.

Furthermore if smarthost setup is changed when mailcow is already
running, the event handler `events/smarthost-changed/10reload_services`
restarts the main module service.

See also the `systemd/user/mailcow.service` file.

This setting discovery is just an example to understand how the module is
expected to work: it can be rewritten or discarded completely.

## Debug

some CLI are needed to debug

- The module runs under an agent that initiate a lot of environment variables (in /home/mailcow1/.config/state), it could be nice to verify them
  on the root terminal

      `runagent -m mailcow1 env`

- you can become runagent for testing scripts and initiate all environment variables

  `runagent -m mailcow1`

the path become :

```
    echo $PATH
    /home/mailcow1/.config/bin:/usr/local/agent/pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/
```

- if you want to debug a container or see environment inside
  `runagent -m mailcow1`

```
podman ps
CONTAINER ID  IMAGE                                      COMMAND               CREATED        STATUS        PORTS                    NAMES
d292c6ff28e9  localhost/podman-pause:4.6.1-1702418000                          9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  80b8de25945f-infra
d8df02bf6f4a  docker.io/library/mariadb:10.11.5          --character-set-s...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  mariadb-app
9e58e5bd676f  docker.io/library/nginx:stable-alpine3.17  nginx -g daemon o...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  mailcow-app
```

you can see what environment variable is inside the container

```
podman exec  mailcow-app env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM=xterm
PKG_RELEASE=1
MARIADB_DB_HOST=127.0.0.1
MARIADB_DB_NAME=mailcow
MARIADB_IMAGE=docker.io/mariadb:10.11.5
MARIADB_DB_TYPE=mysql
container=podman
NGINX_VERSION=1.24.0
NJS_VERSION=0.7.12
MARIADB_DB_USER=mailcow
MARIADB_DB_PASSWORD=mailcow
MARIADB_DB_PORT=3306
HOME=/root
```

you can run a shell inside the container

```
podman exec -ti   mailcow-app sh
/ #
```

## Testing

Test the module using the `test-module.sh` script:

    ./test-module.sh <NODE_ADDR> ghcr.io/geniusdynamics/mailcow:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org]((https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
