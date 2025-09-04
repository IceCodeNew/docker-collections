# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:latest AS distroless-uv
FROM mirror.gcr.io/icecodexi/python:debian-nonroot AS uv
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/
ENV PATH="/home/nonroot/.local/bin:${PATH}" \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1

FROM uv AS build
ARG ver_markitdown
RUN uv --no-progress tool install "markitdown[all]==${ver_markitdown}"


FROM mirror.gcr.io/icecodexi/python:debian-nonroot AS base
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

COPY --link --from=build --chown=65532:65532 \
    /home/nonroot/.local/ /home/nonroot/.local/

ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"
ENTRYPOINT [ "catatonit", "-g", "--", "markitdown" ]
