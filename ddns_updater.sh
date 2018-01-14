#!/bin/sh

# Copyright (c) 2011-2017 Jeff Schornick <code@schornick.org>
# Licensed under The MIT License
# http://www.opensource.org/licenses/mit-license.php


. $(dirname $0)/linode_dns_lib.sh

# Configuration is in /etc/config/ddns
DOMAIN=mydomain
HOSTNAME=myhostname
API_KEY=$(cat linode_api.key)

STATE_FILE=/var/cache/linode_ddns.$HOSTNAME.$DOMAIN

IFACE=wlp2s0
WAN_IP=$(ip addr show ${IFACE} | sed -n 's/.*inet \(.*\)\/.*/\1/p')

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

