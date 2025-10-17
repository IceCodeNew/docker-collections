FROM oven/bun:1-alpine
WORKDIR /home/bun/app/
USER bun:bun

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN --mount=type=bind,from=src_dir,source=./package.json,target=./package.json \
    --mount=type=bind,from=src_dir,source=./bun.lock,target=./bun.lock \
    bun install --frozen-lockfile --production --ignore-scripts --no-cache
COPY --link --from=src_dir --chown=1000:1000 --chmod=755 \
    ./entrypoint.sh ./entrypoint.sh
COPY --link --from=builder --chown=1000:1000 \
    ./              ./dist/

RUN apk update; apk --no-progress --no-cache add \
        bash ca-certificates catatonit; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*

EXPOSE 4141
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --spider -q http://localhost:4141/ || exit 1

ENTRYPOINT [ "catatonit", "--", "/home/bun/app/entrypoint.sh" ]
