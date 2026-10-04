# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:e9328168e7241e8d362094b9246d1843f901ff0106b6b7c8df42c54c7f2c9573 AS catatonit
FROM mirror.gcr.io/cloudflare/cloudflared:2026.9.3@sha256:072c067d25ccbe61d46e18f0d0723255f2bb5304f7317caa95b27031520ff92c AS cloudflared
FROM dhi.io/deno:2.9.7-debian13-dev@sha256:28cf8d28554caa147f21d278cb3e49921b5f23cd05cce2c5a24f56becb1bd981 AS deps
WORKDIR /app
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# renovate: datasource=npm depName=npm packageName=npm
ARG NPM_VERSION=11.6.2
# Deno runs npm to preserve the upstream package-lock.json.
RUN --mount=type=bind,from=src_dir,source=./package.json,target=./package.json \
    --mount=type=bind,from=src_dir,source=./package-lock.json,target=./package-lock.json \
    DENO_DIR=/tmp/npm-cache deno run -A --no-lock --node-modules-dir=none \
        npm:npm@${NPM_VERSION} ci --omit=dev --ignore-scripts --no-audit --no-fund \
    && rm -rf /tmp/npm-cache /root/.npm

FROM deps AS assets
ARG FETCH_ASSETS=1
COPY --link --from=src_dir ./package.json ./package.json
COPY --link --from=src_dir ./shared ./shared
COPY --link --from=src_dir ./server ./server
COPY --link --from=src_dir ./tools ./tools
COPY --link --from=src_dir ./data ./data
COPY --link --from=src_dir ./public ./public
COPY --link --from=src_dir ./docs/research ./docs/research
COPY --link --from=src_dir ./LICENSE ./NOTICE.md ./THIRD-PARTY-NOTICES.md ./
COPY --link ./verify-assets.ts /usr/local/lib/stronghold-protocol/verify-assets.ts
COPY --link ./entrypoint.ts ./healthcheck.ts /runtime/usr/local/lib/stronghold-protocol/
RUN deno run -A --no-lock --node-modules-dir=manual tools/vendor.mjs \
    && case "$FETCH_ASSETS" in \
        1) deno run -A --no-lock --node-modules-dir=manual tools/fetch-assets.mjs \
            && deno run --allow-read /usr/local/lib/stronghold-protocol/verify-assets.ts ;; \
        0) ;; \
        *) echo 'FETCH_ASSETS must be 0 or 1.' >&2; exit 1 ;; \
    esac \
    && deno cache --no-lock --node-modules-dir=manual server/index.js \
    && rm -rf .cache tools \
    && mv /app /deno-dir /runtime/ \
    && chmod -R u=rwX,go=rX /runtime \
    && chmod 0644 /runtime/usr/local/lib/stronghold-protocol/*.ts \
    && chown -R 1993:1993 /runtime/deno-dir

FROM dhi.io/deno:2.9.7-debian13@sha256:6f0d61dbec987508d26ec6a3e95a6f67c3332221f05958ebd3a661064f60e0f4
ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0
WORKDIR /app
COPY --link --from=catatonit /usr/bin/catatonit /usr/bin/catatonit
COPY --link --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/cloudflared
# Copy complete directories so --link preserves their modes and cache ownership.
COPY --link --from=assets /runtime/ /

USER 1993:1993
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/usr/local/bin/deno", "run", "--allow-net", "--allow-env=PORT", "/usr/local/lib/stronghold-protocol/healthcheck.ts"]
ENTRYPOINT ["/usr/bin/catatonit", "--", "/usr/local/bin/deno", "run", "--allow-run=/usr/local/bin/deno,/usr/local/bin/cloudflared", "--allow-read", "--allow-env", "/usr/local/lib/stronghold-protocol/entrypoint.ts"]
CMD ["server/index.js"]
