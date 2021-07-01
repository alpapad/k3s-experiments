#!/bin/sh
set -e

info() {
    echo '[INFO] ' "$@"
}

DNS=$(grep "nameserver" /etc/resolv.conf | head -n 1 |awk '{split($0,a,"\\s*"); print a[2]}')
IP=$(resolveip -s $(hostname))
BK=$(date +"%Y%m%d%M%s.%N")

info "Local IP:${IP}, Current DNS: ${DNS}"

FILE=/etc/unbound/unbound.conf
BACKUPFILE=${FILE}.orig
if [ ! -f "$FILE" ]; then
    info "Copying ${FILE} to ${BACKUPFILE}"
    cp ${FILE} ${BACKUPFILE}
fi

info "Creating new unbound conf as ${FILE}"
tee ${FILE} >/dev/null << EOF
server:
  verbosity: 1
  interface: 127.0.0.1
  port: 53
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes

  access-control: 10.0.0.0/8 allow
  access-control: 127.0.0.0/8 allow
  access-control: 192.168.0.0/16 allow
  # root-hints: "/var/unbound/etc/root.hints"

  hide-identity: yes
  hide-version: yes
  harden-glue: yes

  harden-dnssec-stripped: yes
  use-caps-for-id: yes
  cache-min-ttl: 3600
  cache-max-ttl: 86400

  prefetch: yes
  num-threads: 4
  msg-cache-slabs: 8
  rrset-cache-slabs: 8
  infra-cache-slabs: 8
  key-cache-slabs: 8
  rrset-cache-size: 256m
  msg-cache-size: 128m
  so-rcvbuf: 1m

  #private-address: 192.168.0.0/16
  private-address: 172.16.0.0/12
  #private-address: 10.0.0.0/8

  private-domain: "k3s.local"
  unwanted-reply-threshold: 10000

  do-not-query-localhost: no

  # auto-trust-anchor-file: "/var/unbound/etc/root.key"

  val-clean-additional: yes

  local-zone: "k3s.local." redirect
  local-data: "k3s.local. IN A ${IP}"


  forward-zone:
   name: "."
   forward-addr: ${DNS}@53

EOF


info "Remember to change your nameserver to ${IP} (in /etc/resolv.conf)"