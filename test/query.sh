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
IPS=(142.250.186.78 2a00:1450:4001:809::200e)
QTYPES=(A NS CNAME SOA MX TXT AAAA SRV NAPTR OPT RRSIG DNSKEY TLSA HTTPS URI CAAA)

# single queries over udp
for DOMAIN in "${DOMAINS[@]}" "${HOSTS[@]}"
do
    for QTYPE in "${QTYPES[@]}"
    do
        dig @"${DNS_SERVER}" "$DOMAIN" "$QTYPE"
    done
done

# single queries over tcp
for DOMAIN in "${DOMAINS[@]}" "${HOSTS[@]}"
do
    for QTYPE in "${QTYPES[@]}"
    do
        dig +tcp @"${DNS_SERVER}" "$DOMAIN" "$QTYPE"
    done
done

# single PTR queries over udp
for IP in "${IPS[@]}"
do
    host -U "$IP" "$DNS_SERVER"
done

# single PTR queries over tcp
for IP in "${IPS[@]}"
do
    host -T "$IP" "$DNS_SERVER"
done

# multiple queries over one tcp connection
for DOMAIN in "${DOMAINS[@]}"
do
    dig +tcp +keepopen @"${DNS_SERVER}" "$DOMAIN" A "$DOMAIN" MX "www.$DOMAIN" A 
done

# pipelined queries
mdig @"${DNS_SERVER}" "${DOMAINS[@]}"
mdig @"${DNS_SERVER}" "${HOSTS[@]}"
