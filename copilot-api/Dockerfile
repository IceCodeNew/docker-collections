# syntax=mirror.gcr.io/docker/dockerfile:1

FROM oven/bun:1-alpine AS assets
WORKDIR /home/bun/app/

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN --mount=type=bind,from=src_dir,source=./package.json,target=./package.json \
    --mount=type=bind,from=src_dir,source=./bun.lock,target=./bun.lock \
    bun install --frozen-lockfile --production --ignore-scripts --no-cache
COPY --link --from=src_dir --chmod=755 \
    ./entrypoint.sh ./entrypoint.sh
COPY --link --from=builder \
    ./              ./dist/


FROM oven/bun:1-alpine
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN apk update; apk --no-progress --no-cache add \
        bash ca-certificates catatonit; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*
COPY --link --from=assets --chown=1000:1000 \
    /home/bun/app/ /home/bun/app/

EXPOSE 4141
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --spider -q http://localhost:4141/ || exit 1

WORKDIR /home/bun/app/
USER 1000:1000
ENTRYPOINT [ "catatonit", "--", "/home/bun/app/entrypoint.sh" ]
