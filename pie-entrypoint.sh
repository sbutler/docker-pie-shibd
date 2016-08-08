#!/bin/bash
set -e

echoerr () { echo "$@" 1>&2; }

if [[ "$1" == "shibd-pie" ]]; then
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
