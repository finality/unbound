#!/bin/sh
set -eu

: "${UNBOUND_PORT:=5053}"
: "${UNBOUND_VERBOSITY:=1}"
: "${UNBOUND_BIN:=/usr/local/sbin/unbound}"

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

if [ ! -x "${UNBOUND_BIN}" ]; then
  echo "unbound entrypoint: binary is missing or not executable at ${UNBOUND_BIN}" >&2
  ls -ld /usr/local /usr/local/bin /usr/local/sbin 2>/dev/null >&2 || true
  ls -l /usr/local/bin /usr/local/sbin 2>/dev/null >&2 || true
  exit 127
fi

if ! "${UNBOUND_BIN}" -V >/dev/null 2>&1; then
  echo "unbound entrypoint: runtime self-check failed for ${UNBOUND_BIN}" >&2
  "${UNBOUND_BIN}" -V >&2 || true
  exit 127
fi

exec "${UNBOUND_BIN}" -d -c "${CONFIG_PATH}"
