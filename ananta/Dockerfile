# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:latest AS distroless-uv
FROM cgr.dev/chainguard/python:latest-dev AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1
RUN uv tool install 'ananta[speed]'


FROM mirror.gcr.io/tianon/toybox:latest AS toybox
FROM mirror.gcr.io/library/alpine:latest AS assets
COPY --link --from=toybox /usr/bin/ /emptydir/usr/bin/
RUN rm -f /emptydir/usr/bin/bash /emptydir/usr/bin/sh
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
    && rm -rf /var/cache/apk/* \
    && cp -af /usr/bin/catatonit /emptydir/usr/bin/


FROM mirror.gcr.io/icecodexi/bash-static:latest AS bash-static
FROM cgr.dev/chainguard/python:latest
# toybox - bash -sh + catatonit
COPY --link --from=assets /emptydir/usr/bin/    /usr/bin/
COPY --link --chmod=0755 ./docker-entrypoint.sh /usr/bin/
COPY --link --from=bash-static         /bin/        /bin/

# be aware of the ownership of /home/nonroot/
# refer to: https://github.com/moby/buildkit/issues/4964
COPY --link --from=build --chown=65532:65532 /home/nonroot/ /home/nonroot/

ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"

ENTRYPOINT [ "/usr/bin/docker-entrypoint.sh" ]
