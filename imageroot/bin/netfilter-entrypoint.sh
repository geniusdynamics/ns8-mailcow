#!/bin/sh

#
# Copyright (C) 2026 Genius Dynamics
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Entrypoint of netfilter-mailcow in the pod.
#
# NS8 cannot run one unit of a rootless module as root, so netfilter works
# on the network namespace of the mailcow pod, with NET_ADMIN and NET_RAW
# over that namespace only. Every mail connection reaches the namespace with
# the real client address (bin/create-pod), so a ban there blocks the client
# on all the mailcow ports. The node firewall is left to CrowdSec.
#
# - rootful: netfilter needs a filter table with an input hook to insert its
#   MAILCOW chain; the empty namespace has none, so create it
# - external: no table, netfilter finds no chain and only keeps the ban list
#   in Redis (manage_external, see bin/netfilter-prepare)
#
# The nftables backend is forced: the iptables-legacy backend would need
# kernel modules that a rootless container cannot load.

if [ "${NETFILTER_MODE}" = "rootful" ]; then
    nft -f - <<'NFT'
table ip filter {
    chain INPUT {
        type filter hook input priority filter; policy accept;
    }
}
table ip6 filter {
    chain INPUT {
        type filter hook input priority filter; policy accept;
    }
}
NFT
else
    nft delete table ip filter 2>/dev/null
    nft delete table ip6 filter 2>/dev/null
fi

exec python -u /app/main.py nftables
