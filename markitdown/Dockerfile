# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM ghcr.io/astral-sh/uv:0.12.23@sha256:61d393e44e249f2e4b526b6c7ddcecce245946826e608e11c93ad4f5bba55b21 AS distroless-uv
FROM mirror.gcr.io/icecodexi/python:debian-nonroot@sha256:e3d007fe4783d964e17041cdfe5f884218581224cc0d1d341e4151942e89c88b AS uv
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/
ENV PATH="/home/nonroot/.local/bin:${PATH}" \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1

FROM uv AS build
ARG ver_markitdown
# FIXME: --prerelease=allow is a temp fix for azure-ai-contentunderstanding dependency.
# Revert once upstream resolves the pre-release requirement.
RUN uv --no-progress tool install --prerelease=allow "markitdown[all]==${ver_markitdown}"


FROM mirror.gcr.io/icecodexi/python:debian-nonroot@sha256:e3d007fe4783d964e17041cdfe5f884218581224cc0d1d341e4151942e89c88b AS base
ENV EXIFTOOL_PATH=/usr/bin/exiftool \
    FFMPEG_PATH=/usr/bin/ffmpeg
ARG DEBIAN_FRONTEND=noninteractive
USER root:root
RUN install_packages \
        exiftool ffmpeg
USER nonroot:nonroot

FROM base
ARG ver_markitdown
LABEL org.opencontainers.image.version="${ver_markitdown}" \
      org.opencontainers.image.source="https://github.com/IceCodeNew/docker-collections"

COPY --link --from=build --chown=65532 \
    /home/nonroot/.local/ /home/nonroot/.local/

ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"
ENTRYPOINT [ "catatonit", "-g", "--", "markitdown" ]
