# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:latest AS distroless-uv
FROM cgr.dev/chainguard/python:latest-dev AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1
RUN uv tool install 'ananta[speed]'


FROM mirror.gcr.io/library/alpine:latest AS catatonit
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
    && rm -rf /var/cache/apk/*;


FROM cgr.dev/chainguard/python:latest
# be aware of the ownership of /home/nonroot/
# refer to: https://github.com/moby/buildkit/issues/4964
COPY --link --from=build --chown=65532:65532 /home/nonroot/ /home/nonroot/
COPY --link --from=catatonit                 /usr/bin/catatonit /usr/bin/

ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"

ENTRYPOINT [ "catatonit", "--", "ananta" ]
