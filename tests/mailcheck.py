#!/usr/bin/env python3

#
# Copyright (C) 2026 Genius Dynamics
# SPDX-License-Identifier: GPL-3.0-or-later
#

"""Mail checks run on the node by mailcow.robot

  mailcheck.py banner HOST PORT [tls]     print the greeting of the server
  mailcheck.py smtp-auth HOST PORT USER PASSWORD
                                          STARTTLS, AUTH; print the result
  mailcheck.py imap-login HOST PORT USER PASSWORD
                                          STARTTLS, LOGIN; print the result
"""

import imaplib
import smtplib
import socket
import ssl
import sys


def tls_context():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def banner(host, port, tls=False):
    sock = socket.create_connection((host, port), timeout=30)
    if tls:
        sock = tls_context().wrap_socket(sock, server_hostname=host)
    data = b""
    while b"\n" not in data:
        chunk = sock.recv(1024)
        if not chunk:
            break
        data += chunk
    sock.close()
    print(data.decode(errors="replace").splitlines()[0] if data else "")


def smtp_auth(host, port, user, password):
    client = smtplib.SMTP(host, port, timeout=60)
    client.ehlo("mailcheck.example.org")
    client.starttls(context=tls_context())
    client.ehlo("mailcheck.example.org")
    try:
        client.login(user, password)
        print("authenticated")
    except smtplib.SMTPAuthenticationError as ex:
        print(f"rejected {ex.smtp_code}")
    finally:
        client.quit()


def imap_login(host, port, user, password):
    client = imaplib.IMAP4(host, port, timeout=60)
    client.starttls(ssl_context=tls_context())
    try:
        client.login(user, password)
        print("authenticated")
    except imaplib.IMAP4.error as ex:
        print(f"rejected {ex}")
    finally:
        client.logout()


def main():
    cmd, host, port = sys.argv[1], sys.argv[2], int(sys.argv[3])
    if cmd == "banner":
        banner(host, port, len(sys.argv) > 4 and sys.argv[4] == "tls")
    elif cmd == "smtp-auth":
        smtp_auth(host, port, sys.argv[4], sys.argv[5])
    elif cmd == "imap-login":
        imap_login(host, port, sys.argv[4], sys.argv[5])
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
