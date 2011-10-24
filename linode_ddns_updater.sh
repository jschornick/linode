#!/bin/sh

# Copyright (c) 2011 Jeffrey Schornick
# Licensed under The MIT License
# http://www.opensource.org/licenses/mit-license.php

# Notes:
#
# With openwrt, the real wget package must be installed
# (busybox doesn't support SSL)

. $(dirname $0)/linode_dns_lib.sh

# Configuration is in /etc/config/ddns
DOMAIN=$(uci get ddns.linode.domain)
HOSTNAME=$(uci get ddns.linode.resource)
API_KEY=$(uci get ddns.linode.api_key)

# Openwrt doesn't have the root certs to verify the remote cert
WGET="wget --no-check-certificate "

DOMAIN_ID=$(DomainFind $DOMAIN)

RES_ID=$(DomainResFind $DOMAIN_ID $HOSTNAME)

DNS_IP=$(DomainResGet $DOMAIN_ID $RES_ID TARGET)

echo $HOSTNAME.$DOMAIN: $DNS_IP

IFACE=$(uci get network.wan.ifname)
WAN_IP=$(ifconfig $IFACE | awk '/inet/ {print $2}' | sed 's/addr://')

echo wan IP: $WAN_IP

if [ "$DNS_IP" = "$WAN_IP" ]; then
  echo "Skipping update"
else
  DomainResSet $DOMAIN_ID $RES_ID TARGET $WAN_IP 
  echo
fi

