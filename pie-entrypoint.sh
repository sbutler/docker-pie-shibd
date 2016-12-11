#!/bin/bash
set -e

echoerr () { echo "$@" 1>&2; }

if [[ "$1" == "shibd-pie" ]]; then
  local_ipinfo=($(ip add show eth0 | perl -MNetAddr::IP -lne 'if (m#inet ([\d.]+/\d+) scope global#) { my $n = NetAddr::IP->new($1); printf "%s %s", $n->addr, $n->network; exit 0; }'))
  [[ -z "$SHIBD_TCPLISTENER_ADDRESS" ]] && SHIBD_TCPLISTENER_ADDRESS=${local_ipinfo[0]}
  [[ -z "$SHIBD_TCPLISTENER_ACL" ]]     && SHIBD_TCPLISTENER_ACL=${local_ipinfo[1]}

  echoerr "SHIBD_SERVER_ADMIN=${SHIBD_SERVER_ADMIN}"
  echoerr "SHIBD_TCPLISTENER_ADDRESS=${SHIBD_TCPLISTENER_ADDRESS}"
  echoerr "SHIBD_TCPLISTENER_ACL=${SHIBD_TCPLISTENER_ACL}"
  echoerr "SHIBD_ENTITYID=${SHIBD_ENTITYID}"
  echoerr "SHIBD_ATTRIBUTES=${SHIBD_ATTRIBUTES}"

  for tt2_f in /etc/opt/pie/shibboleth/*.tt2; do
    f="$(basename -s .tt2 "$tt2_f")"
    echoerr "Processing $tt2_f -> $f..."
    tpage \
      --define "shibd_server_admin=${SHIBD_SERVER_ADMIN}" \
      --define "shibd_tcplistener_address=${SHIBD_TCPLISTENER_ADDRESS}" \
      --define "shibd_tcplistener_acl=${SHIBD_TCPLISTENER_ACL}" \
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
