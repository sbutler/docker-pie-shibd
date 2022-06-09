#!/bin/bash
set -e

echoerr () { echo "$@" 1>&2; }

shib_loginit () {
  echoerr "SHIBD_LOGGING=${SHIBD_LOGGING}"

  chown _shibd:_shibd /var/log/shibboleth
  chmod 0750 /var/log/shibboleth

  for f in /var/log/shibboleth/{transaction,signature}.log; do
    case "$SHIBD_LOGGING" in
      pipe)
        [[ -e $f && ! -p $f ]] && rm -- "$f"

        if [[ ! -e $f ]]; then
            mkfifo -m 0640 "$f"
        else
            chmod 0640 "$f"
        fi
        chown _shibd:_shibd "$f"
        ;;

      file)
        [[ -e $f && ! -f $f ]] && rm -- "$f"
        touch "$f"
        chmod 0640 "$f"
        chown _shibd:_shibd "$f"
        ;;

      *)
        [[ -e $f && ! -L $f ]] && rm -- "$f"

        if [[ ! -e $f ]]; then
            ln -s /proc/self/fd/2 "$f"
        fi
        ;;
    esac
  done
}

if [[ "$1" == "shibd-pie" ]]; then
  shib_loginit
  if [[ $SHIBD_LISTENER == "tcp" ]]; then
    local_ipinfo=($(ip addr show eth0 | perl -MNetAddr::IP -lne 'if (m#inet ([\d.]+/\d+).*scope global#) { my $n = NetAddr::IP->new($1); printf "%s %s", $n->addr, $n->network; exit 0; }'))
    [[ -z "$SHIBD_TCPLISTENER_ADDRESS" ]] && SHIBD_TCPLISTENER_ADDRESS=${local_ipinfo[0]}
    [[ -z "$SHIBD_TCPLISTENER_ACL" ]]     && SHIBD_TCPLISTENER_ACL=${local_ipinfo[1]}
  elif [[ $SHIBD_LISTENER == "awsvpc" ]]; then
    # AWSVPC tasks obscure the IP in odd ways and we can't just detect it; use the
    # recommended way in the docs:
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-metadata.html
    awsvpc_ip=$(cat /etc/hosts | tail -1 | awk {'print $1'})
    [[ -z "$SHIBD_TCPLISTENER_ADDRESS" ]] && SHIBD_TCPLISTENER_ADDRESS=${awsvpc_ip}
    # We don't have a way to get the subnet mask... just use 0.0.0.0/0 if one was
    # not passed in. Security groups should be the main way to secure this anyway
    [[ -z "$SHIBD_TCPLISTENER_ACL" ]]     && SHIBD_TCPLISTENER_ACL="0.0.0.0/0"
  fi

  echoerr "SHIBD_SERVER_ADMIN=${SHIBD_SERVER_ADMIN}"
  echoerr "SHIBD_TCPLISTENER_ADDRESS=${SHIBD_TCPLISTENER_ADDRESS}"
  echoerr "SHIBD_TCPLISTENER_ACL=${SHIBD_TCPLISTENER_ACL}"
  echoerr "SHIBD_ENTITYID=${SHIBD_ENTITYID}"
  echoerr "SHIBD_ATTRIBUTES=${SHIBD_ATTRIBUTES}"
  echoerr "SHIBD_STORE_DYNAMODB_TABLE=${SHIBD_STORE_DYNAMODB_TABLE}"
  echoerr "SHIBD_STORE_DYNAMODB_REGION=${SHIBD_STORE_DYNAMODB_REGION}"
  echoerr "SHIBD_STORE_DYNAMODB_ENDPOINT=${SHIBD_STORE_DYNAMODB_ENDPOINT}"
  echoerr "SHIBD_SP_KEY=${SHIBD_SP_KEY}"
  echoerr "SHIBD_SP_CERT=${SHIBD_SP_CERT}"

  echoerr "Initializing /etc/shibboleth"
  cp -van /etc/shibboleth-dist/* /etc/shibboleth/ 1>&2

  for tt2_f in /etc/opt/pie/shibboleth/*.tt2; do
    f="$(basename -s .tt2 "$tt2_f")"
    if [[ "$f" == "shibboleth2.xml" ]]; then
        f="$f${SHIBD_CONFIG_SUFFIX}"
    fi

    echoerr "Processing $tt2_f -> $f..."
    tpage \
      --define "shibd_server_admin=${SHIBD_SERVER_ADMIN}" \
      --define "shibd_tcplistener_address=${SHIBD_TCPLISTENER_ADDRESS}" \
      --define "shibd_tcplistener_acl=${SHIBD_TCPLISTENER_ACL}" \
      --define "shibd_entityid=${SHIBD_ENTITYID}" \
      --define "shibd_attributes=${SHIBD_ATTRIBUTES}" \
      --define "store_dynamodb_table=${SHIBD_STORE_DYNAMODB_TABLE}" \
      --define "store_dynamodb_region=${SHIBD_STORE_DYNAMODB_REGION}" \
      --define "store_dynamodb_endpoint=${SHIBD_STORE_DYNAMODB_ENDPOINT}" \
      --define "shibd_logging=${SHIBD_LOGGING}" \
      --define "shibd_sp_key=${SHIBD_SP_KEY}" \
      --define "shibd_sp_cert=${SHIBD_SP_CERT}" \
      "$tt2_f" > "/etc/shibboleth/$f"
  done

  SHIB_HOME=/usr
  SHIBSP_CONFIG="/etc/shibboleth/shibboleth2.xml${SHIBD_CONFIG_SUFFIX}"
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
elif [[ "$1" == "shibd" ]]; then
  shibd_loginit
  exec shibd "$@"
else
  exec "$@"
fi
