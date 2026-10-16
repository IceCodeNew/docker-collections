# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:e9328168e7241e8d362094b9246d1843f901ff0106b6b7c8df42c54c7f2c9573 AS catatonit
FROM mirror.gcr.io/cloudflare/cloudflared:2026.10.0@sha256:9b49eed8f62806d5d45ddf59ecefb5710429598ea6d3fcccd2af938f621b2b07 AS cloudflared
# Local builds without an asset context use the upstream placeholder manifest.
FROM scratch AS asset_bundle
COPY --link --parents --from=src_dir ./data/assets.json /

FROM dhi.io/node:24.22.0-debian13-dev@sha256:ce95ca4a32bd971675ad4cb2cd29a7005e5fd456eebb8f9c19faf5fe4b690a0b AS deps
WORKDIR /app

RUN --mount=type=bind,from=src_dir,source=./package.json,target=./package.json \
    --mount=type=bind,from=src_dir,source=./package-lock.json,target=./package-lock.json \
    npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
    && npm cache clean --force

FROM deps AS tests
WORKDIR /tests
RUN --mount=type=bind,target=/tests \
    node --test entrypoint_test.ts && touch /tmp/stronghold-tests-passed

FROM deps AS app
COPY --link --parents --from=src_dir \
    ./package.json ./shared ./server ./data ./public \
    ./docs/research ./docs/PLUGIN*.md ./docs/plugin-catalog.example.json \
    ./schemas ./test/helpers/battleHarness.js ./tools/assets ./tools/plugin.mjs \
    ./LICENSE ./NOTICE.md ./THIRD-PARTY-NOTICES.md /app/
COPY --link --from=src_dir ./plugins /app/plugin-resources
RUN --mount=type=bind,from=src_dir,source=./tools/vendor.mjs,target=/app/tools/vendor.mjs \
    node tools/vendor.mjs \
    && node --check server/index.js \
    && mkdir -p /app/plugins

FROM dhi.io/node:24.22.0-debian13@sha256:c6ddacf90691f33734423b06682a63b27abeeafee294830455e91c79614ece8b AS runtime
WORKDIR /app
ENV NODE_ENV=production SP_PLUGIN_RESOURCES=/app/plugin-resources
COPY --link --from=catatonit /usr/bin/catatonit /usr/bin/catatonit
COPY --link --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/cloudflared
# Include parent entries to preserve cache ownership with --link.
COPY --link --parents --chmod=u=rwX,go=rX --from=app /./app /
COPY --link --chmod=u=rwX,go=rX --from=asset_bundle / /app/
COPY --link --chmod=u=rwX,go=rX ./entrypoint.ts ./healthcheck.ts /usr/local/lib/stronghold-protocol/
COPY --link --chown=1993:1993 --from=app /app/plugins /app/plugins

USER 1993:1993
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["node", "/usr/local/lib/stronghold-protocol/healthcheck.ts"]
ENTRYPOINT ["/usr/bin/catatonit", "--", "node", "/usr/local/lib/stronghold-protocol/entrypoint.ts"]
CMD ["node", "server/index.js"]

FROM runtime AS tested
ARG FETCH_ASSETS=0
RUN --mount=type=bind,source=./verify-assets.mjs,target=/verify-assets.mjs \
    ["node", "/verify-assets.mjs", "--image"]
COPY --link --from=tests /tmp/stronghold-tests-passed /tmp/stronghold-tests-passed

FROM runtime AS final
