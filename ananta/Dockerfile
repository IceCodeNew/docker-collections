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
FROM mirror.gcr.io/bitnami/minideb:latest AS assets
COPY --link --from=toybox /usr/bin/ /emptydir/usr/bin/
WORKDIR /emptydir/bin/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN rm -f /emptydir/usr/bin/bash /emptydir/usr/bin/sh \
    && install_packages \
        bash-static \
        catatonit \
    && cp -af /bin/bash-static   /emptydir/bin/bash \
    && ln -sf /bin/bash          /emptydir/bin/sh \
    && cp -af /usr/bin/catatonit /emptydir/usr/bin/


FROM cgr.dev/chainguard/python:latest
# toybox + bash(ash) + catatonit
COPY --link --from=assets /emptydir/ /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN /bin/bash --version || exit 1

COPY --link --chmod=0755 ./docker-entrypoint.sh /usr/local/bin/
# be aware of the ownership of /home/nonroot/
# refer to: https://github.com/moby/buildkit/issues/4964
COPY --link --from=build --chown=65532:65532 /home/nonroot/ /home/nonroot/

ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
