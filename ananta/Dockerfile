# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:latest AS distroless-uv
FROM cgr.dev/chainguard/python:latest-dev AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1
RUN uv tool install 'ananta[speed]'


FROM mirror.gcr.io/library/bash:latest AS bash
FROM mirror.gcr.io/library/alpine:latest AS assets
COPY --link --from=bash   /usr/local/           /emptydir/usr/local/
COPY --link --chmod=0755 ./docker-entrypoint.sh /emptydir/usr/local/bin/
WORKDIR /emptydir/bin/
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
    && rm -rf /var/cache/apk/* \
    && cp -a /usr/bin/catatonit /emptydir/usr/local/bin/ \
    && ln -sf /usr/local/bin/bash /emptydir/bin/bash \
    && ln -sf /usr/local/bin/bash /emptydir/bin/sh


FROM cgr.dev/chainguard/python:latest
COPY --link --from=assets /emptydir/ /
# be aware of the ownership of /home/nonroot/
# refer to: https://github.com/moby/buildkit/issues/4964
COPY --link --from=build --chown=65532:65532 /home/nonroot/ /home/nonroot/

ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
