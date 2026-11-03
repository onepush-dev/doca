# Doca on Railway: the official image (pinned by digest) plus a start wrapper that
# fixes /data volume ownership, derives DOCA_ORIGIN/DOCA_PORT from Railway, starts Doca,
# and creates the first administrator from DOCA_ADMIN_LOGIN / DOCA_ADMIN_PASSWORD.
FROM docker.io/smartdoca/doca:0.2.32@sha256:6ccaaa117a2d06e5b1749eeb1c38363f3cac0ff76c0085dbbed54644fdd6890a
LABEL org.opencontainers.image.source="https://github.com/onepush-dev/doca" \
      org.opencontainers.image.licenses="MIT"
USER root
# Railway's healthcheck uses its own Host header; Doca answers 421 to any host other than
# DOCA_ORIGIN. Let only the read-only GET /health and /live probes through for any host.
COPY railway/patch-health-host.mjs /tmp/patch-health-host.mjs
RUN node /tmp/patch-health-host.mjs && rm /tmp/patch-health-host.mjs
COPY --chmod=755 railway/railway-start.sh /app/railway-start.sh
ENV PORT=39120 \
    DOCA_ADMIN_LOGIN=admin \
    DOCA_TRUST_PROXY=10.0.0.0/8,100.64.0.0/10,172.16.0.0/12,192.168.0.0/16,fd00::/8 \
    DOCA_AI_SQLITE_PATH=/data/ai.db \
    DOCA_PLUGIN_DATABASE_PATH=/data/doca.db.plugins.db \
    DOCA_PLUGINS_DIR=/data/plugins
CMD ["bash", "/app/railway-start.sh"]
