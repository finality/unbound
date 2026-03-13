#!/bin/sh
set -eu

: "${UNBOUND_PORT:=5053}"
: "${UNBOUND_VERBOSITY:=1}"

CONFIG_PATH="/etc/unbound/unbound.conf"

cat >"${CONFIG_PATH}" <<EOF
server:
  username: ""
  directory: "/etc/unbound"
  chroot: ""
  interface: 0.0.0.0
  port: ${UNBOUND_PORT}
  verbosity: ${UNBOUND_VERBOSITY}
  do-ip4: yes
  do-ip6: yes
  do-udp: yes
  do-tcp: yes
  hide-identity: yes
  hide-version: yes
  harden-glue: yes
  harden-dnssec-stripped: yes
  qname-minimisation: yes
  prefetch: yes
  rrset-roundrobin: yes
  use-caps-for-id: no
  edns-buffer-size: 1232
  tls-cert-bundle: "/etc/pki/tls/certs/ca-bundle.crt"
  access-control: 127.0.0.0/8 allow
  access-control: ::1 allow
EOF

for fragment in /config/*.conf; do
  [ -e "${fragment}" ] || continue
  printf 'include: "%s"\n' "${fragment}" >>"${CONFIG_PATH}"
done

exec /usr/local/sbin/unbound -d -c "${CONFIG_PATH}"
