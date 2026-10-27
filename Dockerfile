# Filestash publishes only a rolling :latest tag (no version tags), so this is
# the :latest build of 2026-06-23 pinned by its multi-arch index digest. Bump
# the digest deliberately, after CI passes.
FROM docker.io/machines/filestash:latest@sha256:5348a9f12780379929999d08fa1423d5fd820fd5b1aed6591533681538f94646

ARG TARGETARCH=amd64
USER root

# jq 1.7.1 (static musl binary) and Caddy v2.11.7, each checked against the
# checksum from upstream's published checksums file (jq: sha256sum.txt, Caddy:
# caddy_<version>_checksums.txt). Bump versions and checksums together.
ARG JQ_VERSION=1.7.1
ARG JQ_SHA256_AMD64=5942c9b0934e510ee61eb3e30273f1b3fe2590df93933a93d7c58b81d19c8ff5
ARG JQ_SHA256_ARM64=4dd2d8a0661df0b22f1bb9a1f9830f06b6f3b8f7d91211a1ef5d7c4f06a8b4a5
ARG CADDY_VERSION=2.11.7
ARG CADDY_SHA512_AMD64=a7a433a1b133efc3c8d10eb0b99d52a24b5ef5c322dc77f5282182b1c0402139ab83f3a99f0c52409df77d20123fb0b523edad8a66d8f5e49136197bf61ef0e7
ARG CADDY_SHA512_ARM64=3db36ba90c7a6e8dda40ee3dd71fa08844c76b5fb08f61b31e5e78d2ed38e71c51dc7baed875e50d1ca1279196e84302967237386ae87c91ae9f2aaceada682e
RUN set -eu; \
    case "${TARGETARCH}" in \
      amd64) jq_sha="${JQ_SHA256_AMD64}"; caddy_sha="${CADDY_SHA512_AMD64}" ;; \
      arm64) jq_sha="${JQ_SHA256_ARM64}"; caddy_sha="${CADDY_SHA512_ARM64}" ;; \
      *) echo "unsupported TARGETARCH ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${TARGETARCH}" -o /usr/local/bin/jq; \
    echo "${jq_sha}  /usr/local/bin/jq" | sha256sum -c -; \
    chmod +x /usr/local/bin/jq; \
    curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_${TARGETARCH}.tar.gz" -o /tmp/caddy.tar.gz; \
    echo "${caddy_sha}  /tmp/caddy.tar.gz" | sha512sum -c -; \
    tar --no-same-owner -xzf /tmp/caddy.tar.gz -C /usr/local/bin caddy; \
    rm /tmp/caddy.tar.gz; \
    chmod +x /usr/local/bin/caddy; \
    mkdir -p /etc/caddy

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/app/filestash"]
