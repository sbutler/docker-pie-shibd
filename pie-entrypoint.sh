#!/bin/bash
# Copyright (c) 2017 University of Illinois Board of Trustees
# All rights reserved.
#
# Developed by: 		Technology Services
#                      	University of Illinois at Urbana-Champaign
#                       https://techservices.illinois.edu/
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# with the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
#	* Redistributions of source code must retain the above copyright notice,
#	  this list of conditions and the following disclaimers.
#	* Redistributions in binary form must reproduce the above copyright notice,
#	  this list of conditions and the following disclaimers in the
#	  documentation and/or other materials provided with the distribution.
#	* Neither the names of Technology Services, University of Illinois at
#	  Urbana-Champaign, nor the names of its contributors may be used to
#	  endorse or promote products derived from this Software without specific
#	  prior written permission.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH
# THE SOFTWARE.

set -e

echoerr () { echo "$@" 1>&2; }

if [[ "$1" == "shibd-pie" ]]; then
  local_ipinfo=($(ip addr show eth0 | perl -MNetAddr::IP -lne 'if (m#inet ([\d.]+/\d+).*scope global#) { my $n = NetAddr::IP->new($1); printf "%s %s", $n->addr, $n->network; exit 0; }'))
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
