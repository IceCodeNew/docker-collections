# syntax=docker/dockerfile:1


FROM ghcr.io/astral-sh/uv:latest AS distroless-uv
FROM cgr.dev/chainguard/python:latest-dev AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1
RUN uv tool install 'ananta[speed]'


FROM cgr.dev/chainguard/python:latest AS assets
# be aware of the ownership of /home/nonroot/
# refer to: https://github.com/moby/buildkit/issues/4964
COPY --from=build --chown=nonroot:nonroot /home/nonroot/ /emptydir/home/nonroot/


FROM cgr.dev/chainguard/python:latest
COPY --link --from=assets /emptydir/ /
WORKDIR /home/nonroot/

ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"

ENTRYPOINT [ "/home/nonroot/.local/bin/ananta" ]
