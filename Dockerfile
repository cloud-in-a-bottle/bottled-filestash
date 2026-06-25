FROM machines/filestash@sha256:5348a9f12780379929999d08fa1423d5fd820fd5b1aed6591533681538f94646

ARG TARGETARCH=amd64
USER root

# jq 1.7.1 (static musl binary) and Caddy v2.9.1 — bump intentionally after testing
RUN curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-${TARGETARCH}" -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq && \
    curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=${TARGETARCH}&version=v2.9.1" -o /usr/local/bin/caddy && \
    chmod +x /usr/local/bin/caddy && \
    mkdir -p /etc/caddy

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/app/filestash"]
