# syntax=docker/dockerfile:1.7

ARG UBI_MINIMAL_IMAGE=registry.access.redhat.com/ubi9/ubi-minimal:latest
ARG UNBOUND_VERSION=1.24.2
ARG UNBOUND_SHA256=44e7b53e008a6dcaec03032769a212b46ab5c23c105284aa05a4f3af78e59cdb

FROM ${UBI_MINIMAL_IMAGE} AS builder
ARG UNBOUND_VERSION
ARG UNBOUND_SHA256

RUN microdnf install -y --setopt=install_weak_deps=0 --setopt=tsflags=nodocs \
      ca-certificates \
      curl-minimal \
      diffutils \
      expat \
      expat-devel \
      gcc \
      gzip \
      libevent-devel \
      make \
      openssl-devel \
      tar \
    && microdnf clean all

WORKDIR /tmp

RUN curl -fsSLO "https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz" \
    && echo "${UNBOUND_SHA256}  unbound-${UNBOUND_VERSION}.tar.gz" | sha256sum -c - \
    && tar -xzf "unbound-${UNBOUND_VERSION}.tar.gz"

WORKDIR /tmp/unbound-${UNBOUND_VERSION}

RUN test -f /usr/include/expat.h \
    && ls -l /usr/include/expat.h /usr/lib64/libexpat* \
    && pkg-config --cflags expat \
    && pkg-config --libs expat \
    && ./configure \
      --prefix=/usr/local \
      --sysconfdir=/etc/unbound \
      --with-libexpat=/usr \
      --with-libevent \
      --with-pthreads \
      --with-ssl \
      --disable-flto \
    && make -j"$(nproc)" \
    && make install \
    && strip /usr/local/sbin/unbound /usr/local/sbin/unbound-anchor /usr/local/sbin/unbound-checkconf || true \
    && test -x /usr/local/sbin/unbound \
    && /usr/local/sbin/unbound -V >/dev/null \
    && ldd /usr/local/sbin/unbound

FROM ${UBI_MINIMAL_IMAGE}
ARG UNBOUND_VERSION

LABEL org.opencontainers.image.title="Unbound on UBI Minimal" \
      org.opencontainers.image.description="Unbound built from upstream NLnet Labs source on Red Hat UBI Minimal." \
      org.opencontainers.image.version="${UNBOUND_VERSION}"

RUN microdnf install -y --setopt=install_weak_deps=0 --setopt=tsflags=nodocs \
      ca-certificates \
      expat \
      libevent \
      openssl-libs \
      shadow-utils \
    && microdnf clean all \
    && groupadd --system --gid 10001 unbound \
    && useradd --system --uid 10001 --gid 10001 --home-dir /var/lib/unbound --shell /sbin/nologin unbound \
    && mkdir -p /config /etc/unbound /var/lib/unbound \
    && chown -R unbound:unbound /config /etc/unbound /var/lib/unbound

COPY --from=builder /usr/local /usr/local
COPY --chown=10001:10001 entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 0755 /usr/local/bin/entrypoint.sh \
    && test -x /usr/local/sbin/unbound \
    && ldd /usr/local/sbin/unbound \
    && /usr/local/sbin/unbound -V >/dev/null

USER 10001:10001

ENV UNBOUND_PORT=5053
ENV UNBOUND_VERBOSITY=1

EXPOSE 5053/tcp 5053/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
