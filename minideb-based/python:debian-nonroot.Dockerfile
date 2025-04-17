# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:latest AS distroless-uv
FROM mirror.gcr.io/bitnami/minideb:latest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/

RUN install_packages python3 \
    && groupadd --gid 65532 nonroot \
    && useradd --uid 65532 --gid nonroot --shell /bin/bash --create-home nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot/
ENV PATH="/home/nonroot/.local/bin:${PATH}" \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1
