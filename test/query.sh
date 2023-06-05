#!/bin/bash
# Author: Juergen Mang <juergen.mang@axians.de>
# Date: 2023-06-05
#
# Simple test script
# Usage: ./query.sh <nameserver>
#
# -------------------------------------------------------------------------
# See the file "LICENSE.md" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# -------------------------------------------------------------------------

if [ -z "$1" ]
then
    echo "$0 <nameserver>"
    exit 1
fi

DNS_SERVER="$1"
DOMAINS=(google.com axians.de github.com)
HOSTS=(www.google.com www.axians.de www.github.com)
QTYPES=(A MX CNAME TXT SRV NS SOA)

# simple udp queries
for DOMAIN in "${DOMAINS[@]}" "${HOSTS[@]}"
do
    for QTYPE in "${QTYPES[@]}"
    do
        host -t "$QTYPE" "$DOMAIN" "$DNS_SERVER"
    done
done

# simple tcp queries
for DOMAIN in "${DOMAINS[@]}" "${HOSTS[@]}"
do
    for QTYPE in "${QTYPES[@]}"
    do
        host -T -t "$QTYPE" "$DOMAIN" "$DNS_SERVER"
    done
done

# ip queries
host 142.250.186.78 "$DNS_SERVER"
host 2a00:1450:4001:809::200e "$DNS_SERVER"

# multiple queries over one tcp connection
for DOMAIN in "${DOMAINS[@]}"
do
    dig +tcp +keepopen @"${DNS_SERVER}" "$DOMAIN" A "$DOMAIN" MX "www.$DOMAIN" A 
done

# pipelined queries
mdig @"${DNS_SERVER}" "${DOMAINS[@]}"
mdig @"${DNS_SERVER}" "${HOSTS[@]}"
