#!/bin/sh

# Copyright (c) 2011 Jeffrey Schornick
# Licensed under The MIT License
# http://www.opensource.org/licenses/mit-license.php

API_URL=https://api.linode.com/

: ${DEBUG:=:}
: ${WGET:=wget}

ApiCall()
{
  $DEBUG "ApiCall ( $1 $2 $3 $4 $5 $6 $7 )" >&2
  function=$1
  shift
  params=""
  while [ x$1 != x ]; do
	key=$1
	val=$2
	shift
	if [ x$val != x ]; then
		shift
	fi
        params=${params}\&${key}=${val}
  done
  $WGET -qO- $API_URL/?api_key=$API_KEY\&api_action=${function}${params}
}

DomainList()
{
  $DEBUG "DomainList( $1 )" >&2
  if [ x$1 = x ]; then
    ApiCall "domain.list"
  else
    ApiCall "domain.list" "DomainId" $1
  fi
}

DomainFind()
{
   $DEBUG "DomainFind( $1 )" >&2
   NAME=$1
   list=$(ApiCall "domain.list")
   ID=$(echo $list | sed -e 's/{/\n{/g' | grep \"DOMAIN\":\"${NAME}\" | sed -e 's/,/\n/g' | grep DOMAINID | cut -d: -f2)
   echo $ID
}

DomainResList()
{
  $DEBUG "DomainResList( $1 $2 )" >&2
  DOMAIN_ID=$1
  shift
  if [ x$1 = x ]; then
    ApiCall "domain.resource.list" "DomainId" $DOMAIN_ID
  else
    ApiCall "domain.resource.list" "DomainId" $DOMAIN_ID ResourceId $1
  fi
}

DomainResGet()
{
  $DEBUG "DomainResGet( $1 $2 $3 )" >&2
  list=$(DomainResList $1 $2)
  KEY=$3
  VAL=$(echo $list | sed -e 's/,/\n/g' | grep \"${KEY}\": | cut -d: -f2)
  echo $VAL | sed -e 's/^"\(.*\)\"$/\1/'
}

DomainResSet()
{
  $DEBUG "DomainResSet( $1 $2 $3 $4 )" >&2
  DOMAIN_ID=$1
  RES_ID=$2
  KEY=$3 
  VAL=$4
  ApiCall "domain.resource.update" DomainId $DOMAIN_ID ResourceId $RES_ID $KEY $VAL
}

DomainResFind()
{
   $DEBUG "DomainResFind( $1 $2 )" >&2
   DOMAIN_ID=$1
   NAME=$2 
   list=$(DomainResList $DOMAIN_ID)

   ID=$(echo $list | sed -e 's/{/\n{/g' | grep \"NAME\":\"${NAME}\" | sed -e 's/,/\n/g' | grep RESOURCEID | cut -d: -f2)
   echo $ID
}

