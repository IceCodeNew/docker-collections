# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/oven/bun:1.3.14-alpine@sha256:5acc90a93e91ff07bf72aa90a7c9f0fa189765aec90b47bdbf2152d2196383c0 AS assets
WORKDIR /home/bun/app/

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN --mount=type=bind,from=src_dir,source=./package.json,target=./package.json \
    --mount=type=bind,from=src_dir,source=./bun.lock,target=./bun.lock \
    bun install --frozen-lockfile --production --ignore-scripts --no-cache
COPY --link --from=src_dir --chmod=755 \
    ./entrypoint.sh ./entrypoint.sh
COPY --link --from=builder \
    ./              ./dist/


FROM mirror.gcr.io/oven/bun:1.3.14-alpine@sha256:5acc90a93e91ff07bf72aa90a7c9f0fa189765aec90b47bdbf2152d2196383c0
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
