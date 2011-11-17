#!/bin/sh

# Copyright (c) 2011 Jeff Schornick <code@schornick.org>
# Licensed under The MIT License
# http://www.opensource.org/licenses/mit-license.php

# Notes:
#
# With Openwrt, the real wget package must be installed
# (busybox doesn't support SSL)

. $(dirname $0)/linode_dns_lib.sh

# Configuration is in /etc/config/ddns
DOMAIN=$(uci get ddns.linode.domain)
HOSTNAME=$(uci get ddns.linode.resource)
API_KEY=$(uci get ddns.linode.api_key)

STATE_FILE=/var/state/linode_ddns.$HOSTNAME.$DOMAIN

# Openwrt doesn't have the root certs to verify the remote cert,
# so override the library's default WGET to skip the check
WGET="wget --no-check-certificate "

IFACE=$(uci get network.wan.ifname)
WAN_IP=$(ifconfig $IFACE | awk '/inet/ {print $2}' | sed 's/addr://')

echo
echo WAN interface IP: $WAN_IP

if [ -f $STATE_FILE ]; then
  LAST_IP=$(cat $STATE_FILE)
  echo State file: $LAST_IP
fi

if [ "$LAST_IP" = "$WAN_IP" ]; then
  echo "Skipping update"
  echo
  exit 0
fi

echo -n "Polling Linode DNS API."
DOMAIN_ID=$(DomainFind $DOMAIN)
echo -n "."
RES_ID=$(DomainResFind $DOMAIN_ID $HOSTNAME)
echo -n "."
LINODE_IP=$(DomainResGet $DOMAIN_ID $RES_ID TARGET)
echo " done."

echo Linode DNS manager \($HOSTNAME.$DOMAIN\): $LINODE_IP

if [ "$LINODE_IP" = "$WAN_IP" ]; then
  echo "Skipping update"
else
  echo -n "Performing update..."
  response=$(DomainResSet $DOMAIN_ID $RES_ID TARGET $WAN_IP)
  echo " done."
  # Don't trust, spend an extra API call to get the actual value
  # before saving to state file
  LINODE_IP=$(DomainResGet $DOMAIN_ID $RES_ID TARGET)
  echo Linode DNS manager entry is now: $LINODE_IP
fi

# even if we skipped the update due to a match, we may still
# need to write a state file
echo $LINODE_IP > $STATE_FILE

echo

exit 0

