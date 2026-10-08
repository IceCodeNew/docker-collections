# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:e9328168e7241e8d362094b9246d1843f901ff0106b6b7c8df42c54c7f2c9573 AS catatonit
FROM mirror.gcr.io/cloudflare/cloudflared:2026.10.0@sha256:9b49eed8f62806d5d45ddf59ecefb5710429598ea6d3fcccd2af938f621b2b07 AS cloudflared
# Local builds without an asset context use the upstream placeholder manifest.
FROM scratch AS asset_bundle
COPY --link --parents --from=src_dir ./data/assets.json /

FROM dhi.io/deno:2.9.7-debian13-dev@sha256:28cf8d28554caa147f21d278cb3e49921b5f23cd05cce2c5a24f56becb1bd981 AS deps
WORKDIR /app

# Deno runs npm to preserve the upstream package-lock.json.
RUN --mount=type=bind,from=src_dir,source=./package.json,target=./package.json \
    --mount=type=bind,from=src_dir,source=./package-lock.json,target=./package-lock.json \
    DENO_DIR=/tmp/npm-cache deno run --allow-read --allow-write --allow-net --allow-env --allow-sys \
        npm:npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
    && rm -rf /tmp/npm-cache /root/.npm

FROM deps AS tests
WORKDIR /tests
ARG TEST_RUNTIME_ARGS
RUN --mount=type=bind,target=/tests \
    deno test -A entrypoint_test.ts && touch /tmp/stronghold-tests-passed

FROM deps AS app
COPY --link --parents --from=src_dir \
    ./package.json ./shared ./server ./data ./public \
    ./docs/research ./LICENSE ./NOTICE.md ./THIRD-PARTY-NOTICES.md /app/
RUN --mount=type=bind,from=src_dir,source=./tools/vendor.mjs,target=/app/tools/vendor.mjs \
    DENO_DIR=/tmp/vendor-cache deno run --allow-read --allow-write tools/vendor.mjs \
    && rm -rf /tmp/vendor-cache \
    && deno cache server/index.js \
    && chown -R 1993:1993 /deno-dir

FROM dhi.io/deno:2.9.7-debian13@sha256:862b393c397b773076121d0a87263bfe9eafa2e79a8609982e0e2749b1c332be AS runtime
WORKDIR /app
COPY --link --from=catatonit /usr/bin/catatonit /usr/bin/catatonit
COPY --link --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/cloudflared
# Include parent entries to preserve cache ownership with --link.
COPY --link --parents --chmod=u=rwX,go=rX --from=app /./app /./deno-dir /
COPY --link --chmod=u=rwX,go=rX --from=asset_bundle / /app/
COPY --link --chmod=u=rwX,go=rX ./entrypoint.ts ./healthcheck.ts /usr/local/lib/stronghold-protocol/

USER 1993:1993
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/usr/local/bin/deno", "run", "--allow-net", "--allow-env=PORT", "/usr/local/lib/stronghold-protocol/healthcheck.ts"]
ENTRYPOINT ["/usr/bin/catatonit", "--", "/usr/local/bin/deno", "run", "--allow-run=/usr/local/bin/deno,/usr/local/bin/cloudflared", "--allow-env", "/usr/local/lib/stronghold-protocol/entrypoint.ts"]
CMD ["/usr/local/bin/deno", "run", "--allow-net", "--allow-read", "--allow-env", "--allow-sys=networkInterfaces", "server/index.js"]

FROM runtime AS tested
ARG FETCH_ASSETS=0
RUN --mount=type=bind,source=./verify-assets.mjs,target=/verify-assets.mjs \
    ["/usr/local/bin/deno", "run", "--allow-read", "--allow-env=FETCH_ASSETS", "/verify-assets.mjs", "--image"]
COPY --link --from=tests /tmp/stronghold-tests-passed /tmp/stronghold-tests-passed

FROM runtime AS final
