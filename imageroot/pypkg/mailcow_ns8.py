#
# Copyright (C) 2026 Genius Dynamics
# SPDX-License-Identifier: GPL-3.0-or-later
#

"""Shared helpers of the mailcow module: settings, secrets and env files"""

import os
import secrets
import string
import sys

import agent

# Values of the netfilter_mode setting, see README.md
NETFILTER_MODES = ("disabled", "external", "rootful")
DEFAULT_NETFILTER_MODE = "external"

# The containers of the pod share one network namespace: every mailcow
# service is reached on the loopback. IPV4_NETWORK is a loopback prefix, so
# the addresses mailcow derives from it (.248 SOGo, .249 Redis, .250
# Dovecot, .253 Postfix) are loopback addresses as well.
IPV4_NETWORK = "127.0.0"
IPV6_NETWORK = "fd4d:6169:6c63:6f77::/64"
COMPOSE_PROJECT_NAME = "mailcowdockerized"

# Units of the pod that always run, in start order
CORE_UNITS = [
    "mailcow.service",
    "mysql-mailcow-app.service",
    "redis-mailcow-app.service",
    "memcached-mailcow-app.service",
    "unbound-mailcow-app.service",
    "dockerapi.service",
    "php-fpm-mailcow-app.service",
    "sogo-mailcow-app.service",
    "dovecot-mailcow-app.service",
    "postfix-tlspol-mailcow-app.service",
    "postfix-mailcow-app.service",
    "olefy-mailcow-app.service",
    "rspamd-mailcow-app.service",
    "nginx-mailcow-app.service",
]
CRON_TIMERS = [
    "mailcow-cron-minutely.timer",
    "mailcow-cron-5min.timer",
    "mailcow-cron-20min.timer",
    "mailcow-cron-30min.timer",
    "mailcow-cron-daily.timer",
]

# Public ports, the same as mailcow-dockerized publishes
MAIL_PORTS = ["25/tcp", "465/tcp", "587/tcp", "143/tcp", "993/tcp",
              "110/tcp", "995/tcp", "4190/tcp"]

SECRETS_FILE = "secrets.env"


def genpw(length=28):
    """Alphanumeric secret, like mailcow's generate_config.sh: the values end
    up in SQL connection URLs and shell scripts of the containers"""
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def write_private_envfile(path, values):
    """Write KEY=VALUE lines readable by the module user only (0600)"""
    tmp = f"{path}.{os.getpid()}.tmp"
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as fenv:
        for key, value in values.items():
            fenv.write(f"{key}={value}\n")
    os.replace(tmp, path)


def read_envfile_or_empty(path):
    try:
        return agent.read_envfile(path)
    except FileNotFoundError:
        return {}


def ensure_secrets():
    """Return the secrets of the instance, generating them once. The
    MariaDB and Redis passwords of the web-only releases are kept: their
    volumes were initialized with them."""
    current = read_envfile_or_empty(SECRETS_FILE)
    old_mysql = read_envfile_or_empty("mysql-mailcow.env")
    old_redis = read_envfile_or_empty("redis-mailcow.env")
    wanted = {
        "DBNAME": old_mysql.get("MYSQL_DATABASE") or "mailcow",
        "DBUSER": old_mysql.get("MYSQL_USER") or "mailcow",
        "DBPASS": old_mysql.get("MYSQL_PASSWORD") or genpw(),
        "DBROOT": old_mysql.get("MYSQL_ROOT_PASSWORD") or genpw(),
        "REDISPASS": old_redis.get("REDISPASS") or genpw(),
        "SOGO_URL_ENCRYPTION_KEY": genpw(16),
    }
    changed = False
    for key, value in wanted.items():
        if not current.get(key):
            current[key] = value
            changed = True
    if changed:
        write_private_envfile(SECRETS_FILE, current)
    return current


def dist_value(name):
    """A value of the vendored mailcow-dockerized release (RELEASE,
    DB_VERSION: the database schema version, x-db-version of its
    docker-compose.yml, that php-fpm, SOGo and Dovecot wait for)"""
    path = os.path.join(os.environ["AGENT_INSTALL_DIR"], "mailcow-dist", name)
    with open(path) as fdist:
        return fdist.read().strip()


def get_timezone():
    """Time zone of the node, for the containers"""
    try:
        target = os.path.realpath("/etc/localtime")
        if "/zoneinfo/" in target:
            return target.split("/zoneinfo/", 1)[1]
    except OSError:
        pass
    return "UTC"


def settings_from_env():
    """Current settings, as stored in the module environment"""
    return {
        "host": os.getenv("MAILCOW_HOSTNAME") or os.getenv("TRAEFIK_HOST", ""),
        "http2https": os.getenv("TRAEFIK_HTTP2HTTPS", "True").lower() == "true",
        "lets_encrypt": os.getenv("TRAEFIK_LETS_ENCRYPT", "False").lower() == "true",
        "netfilter_mode": os.getenv("NETFILTER_MODE", DEFAULT_NETFILTER_MODE),
        "clamd_enabled": os.getenv("CLAMD_ENABLED", "True").lower() == "true",
    }


def mailcow_conf(settings, secrets_map):
    """The variables of mailcow.conf, given to every mailcow container"""
    yes_no = lambda flag: "y" if flag else "n"
    return {
        "MAILCOW_HOSTNAME": settings["host"],
        "MAILCOW_PASS_SCHEME": "BLF-CRYPT",
        "DBNAME": secrets_map["DBNAME"],
        "DBUSER": secrets_map["DBUSER"],
        "DBPASS": secrets_map["DBPASS"],
        "DBROOT": secrets_map["DBROOT"],
        "REDISPASS": secrets_map["REDISPASS"],
        "REDISMASTERPASS": "",
        "REDIS_SLAVEOF_IP": "",
        "REDIS_SLAVEOF_PORT": "",
        # Traefik terminates TLS and talks to nginx on HTTP_PORT; dockerapi
        # owns port 443 of the pod, so nginx keeps its HTTPS server on 8443
        "HTTP_PORT": "80",
        "HTTPS_PORT": "8443",
        "HTTP_REDIRECT": "n",
        "NGINX_MAX_BODY_SIZE": "128m",
        "TRUSTED_PROXIES": "127.0.0.1,::1,169.254.0.0/16",
        "PHPFPMHOST": "127.0.0.1",
        "SOGOHOST": "127.0.0.1",
        "RSPAMDHOST": "127.0.0.1",
        "REDISHOST": "127.0.0.1",
        "ENABLE_IPV6": "false",
        "SMTP_PORT": "25",
        "SMTPS_PORT": "465",
        "SUBMISSION_PORT": "587",
        "IMAP_PORT": "143",
        "IMAPS_PORT": "993",
        "POP_PORT": "110",
        "POPS_PORT": "995",
        "SIEVE_PORT": "4190",
        "TZ": get_timezone(),
        "COMPOSE_PROJECT_NAME": COMPOSE_PROJECT_NAME,
        "ACL_ANYONE": "disallow",
        "MAILDIR_GC_TIME": "7200",
        "MAILDIR_SUB": "Maildir",
        "ADDITIONAL_SAN": "",
        "AUTODISCOVER_SAN": "y",
        "ADDITIONAL_SERVER_NAMES": "",
        # Traefik provides the certificate, see events/certificate-changed
        "SKIP_LETS_ENCRYPT": "y",
        "ENABLE_SSL_SNI": "n",
        "SKIP_IP_CHECK": "y",
        "SKIP_HTTP_VERIFICATION": "y",
        "SKIP_UNBOUND_HEALTHCHECK": "n",
        "SKIP_CLAMD": yes_no(not settings["clamd_enabled"]),
        "SKIP_OLEFY": "n",
        "SKIP_SOGO": "n",
        "SKIP_RSPAMD": "n",
        "SKIP_FTS": "y",
        "FTS_HEAP": "128",
        "FTS_PROCS": "1",
        "ALLOW_ADMIN_EMAIL_LOGIN": "n",
        "USE_WATCHDOG": "n",
        "LOG_LINES": "9999",
        "IPV4_NETWORK": IPV4_NETWORK,
        "IPV6_NETWORK": IPV6_NETWORK,
        "SOGO_EXPIRE_SESSION": "480",
        "SOGO_URL_ENCRYPTION_KEY": secrets_map["SOGO_URL_ENCRYPTION_KEY"],
        "DOVECOT_MASTER_USER": "",
        "DOVECOT_MASTER_PASS": "",
        "MAILCOW_REPLICA_IP": "",
        "DOVEADM_REPLICA_PORT": "",
        "WEBAUTHN_ONLY_TRUSTED_VENDORS": "n",
        "SPAMHAUS_DQS_KEY": "",
        # NS8 has no DOCKER-USER chain and no br-mailcow bridge
        "DISABLE_NETFILTER_ISOLATION_RULE": "y",
        "SNAT_TO_SOURCE": "n",
        "SNAT6_TO_SOURCE": "n",
        "MASTER": "y",
        "DEV_MODE": "n",
        "DEMO_MODE": "n",
        "CLUSTERMODE": "",
        "API_KEY": "",
        "API_KEY_READ_ONLY": "",
        "API_ALLOW_FROM": "",
        "DB_VERSION": dist_value("DB_VERSION"),
    }


def write_env_files(settings):
    """Write the env files of the containers; return True if one changed"""
    secrets_map = ensure_secrets()
    conf = mailcow_conf(settings, secrets_map)
    files = {
        "mailcow.env": conf,
        "mysql.env": {
            "TZ": conf["TZ"],
            "MYSQL_ROOT_PASSWORD": secrets_map["DBROOT"],
            "MYSQL_DATABASE": secrets_map["DBNAME"],
            "MYSQL_USER": secrets_map["DBUSER"],
            "MYSQL_PASSWORD": secrets_map["DBPASS"],
            "MYSQL_INITDB_SKIP_TZINFO": "1",
        },
    }
    changed = False
    for name, values in files.items():
        old = read_envfile_or_empty(name)
        if old != values:
            write_private_envfile(name, values)
            changed = True
    # env files of the web-only releases
    for name in ["unbound-mailcow.env", "clamd-mailcow.env", "sogo-mailcow.env",
                 "dovecot-mailcow.env", "postfix-tlspol-mailcow.env", "nginx-mailcow.env",
                 "dockerapi-mailcow.env", "olefy-mailcow.env", "postfix-mailcow.env",
                 "memcached-mailcow.env", "acme-mailcow.env", "netfilter-mailcow.env",
                 "watchdog-mailcow.env", "redis-mailcow.env", "rspamd-mailcow.env",
                 "ofelia-mailcow.env", "php-fpm-mailcow.env", "mysql-mailcow.env"]:
        try:
            os.unlink(name)
        except FileNotFoundError:
            pass
    return changed


def mail_modules_on_node():
    """Instances of the NS8 mail module (ns8-mail) on this node"""
    node_id = os.environ["NODE_ID"]
    rdb = agent.redis_connect(use_replica=True)
    found = []
    for module_id, mnode in (rdb.hgetall("cluster/module_node") or {}).items():
        if str(mnode) != str(node_id) or module_id == os.environ.get("MODULE_ID"):
            continue
        image_url = rdb.hget(f"module/{module_id}/environment", "IMAGE_URL") or ""
        image_name = image_url.rsplit("/", 1)[-1].split(":", 1)[0].split("@", 1)[0]
        if image_name == "mail":
            found.append(module_id)
    return sorted(found)


def log(message):
    print(message, file=sys.stderr)
