#!/bin/bash
set -e

echoerr () { echo "$@" 1>&2; }

if [[ "$1" == "shibd-pie" ]]; then
  if [[ -z "$SHIBD_ADDRESS" ]]; then
    SHIBD_ADDRESS="$(ip add show eth0 | perl -lne 'if (m#inet ([\d.]+)/(\d+) scope global#) { print $1; exit 0; }')"
  fi

  SHIBD_ATTRIBUTES=" $SHIBD_ATTRIBUTES "

  echoerr "SHIBD_SERVER_ADMIN=${SHIBD_SERVER_ADMIN}"
  echoerr "SHIBD_ADDRESS=${SHIBD_ADDRESS}"
  echoerr "SHIBD_ENTITYID=${SHIBD_ENTITYID}"
  echoerr "SHIBD_ATTRIBUTES=${SHIBD_ATTRIBUTES}"

  for tt2_f in /etc/opt/pie/shibboleth/*.tt2; do
    f="$(basename -s .tt2 "$tt2_f")"
    echoerr "Processing $tt2_f -> $f..."
    tpage \
      --define "shibd_server_admin=${SHIBD_SERVER_ADMIN}" \
      --define "shibd_address=${SHIBD_ADDRESS}" \
      --define "shibd_entityid=${SHIBD_ENTITYID}" \
      --define "shibd_attributes=${SHIBD_ATTRIBUTES}" \
      "$tt2_f" > "/etc/shibboleth/$f"
  done

  SHIB_HOME=/usr
  SHIBSP_CONFIG=/etc/shibboleth/shibboleth2.xml
  LD_LIBRARY_PATH=/usr/lib
  PIDFILE=/var/run/shibboleth/shibd.pid
  DAEMON_OPTS="-F"

  # Force removal of socket
  DAEMON_OPTS="$DAEMON_OPTS -f"

  # Use defined configuration file
  DAEMON_OPTS="$DAEMON_OPTS -c $SHIBSP_CONFIG"

  # Specify pid file to use
  DAEMON_OPTS="$DAEMON_OPTS -p $PIDFILE"

  [ -r /etc/default/shibd ] && . /etc/default/shibd

  rm -f "$PIDFILE"
  exec shibd $DAEMON_OPTS "$@"
else
  exec "$@"
fi
