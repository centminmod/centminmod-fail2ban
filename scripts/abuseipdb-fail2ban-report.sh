#!/bin/bash

REPORTED_IP_LIST_FILE=/home/pi/abuseipdb-reported-ip-list
FAIL2BAN_SQLITE_DB=/var/lib/fail2ban/fail2ban.sqlite3

APIKEY=$1
COMMENT=$2
IP=$3
CATEGORIES=$4
BANTIME=$5

ipMatch=`grep -Fe "IP=$IP L=[0-9\-]+" $REPORTED_IP_LIST_FILE`

shouldBanIP=1
currentTimestamp=`date +%s`

if [ -z $ipMatch ] ; then
  banLength=`echo $ipMatch | sed -E 's/.*L=([0-9\-]+)/\1/'`
  timeOfBan=`sqlite3 $FAIL2BAN_SQLITE_DB "SELECT timeofban FROM bans WHERE ip = '$IP'"`

  if (((banLength == -1 && banLength == BANTIME) || (timeOfBan > 0 && timeOfBan + banLength > currentTimestamp))) ; then
    shouldBanIP=0
  else
    sed -i "/^IP=$IP.*$/d" $REPORTED_IP_LIST_FILE
  fi
fi

if [ $shouldBanIP -eq 1 ] ; then
  echo "IP=$IP L=$BANTIME" >> $REPORTED_IP_LIST_FILE
  curl --fail 'https://api.abuseipdb.com/api/v2/report' \
    -H 'Accept: application/json' \
    -H "Key: $APIKEY" \
    --data-urlencode "comment=$COMMENT" \
    --data-urlencode "ip=$IP" \
    --data "categories=$CATEGORIES"
fi