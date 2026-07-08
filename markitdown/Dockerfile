# syntax=docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM ghcr.io/astral-sh/uv:latest@sha256:0f36cb9361a3346885ca3677e3767016687b5a170c1a6b88465ec14aefec90aa AS distroless-uv
FROM mirror.gcr.io/icecodexi/python:debian-nonroot@sha256:7f85f87ff85fa9f27689b4175ad10a42f7fc6dbe9e1c4b6447da27d5e747f1f4 AS uv
COPY --link --from=distroless-uv /uv /uvx \
    /usr/local/bin/
ENV PATH="/home/nonroot/.local/bin:${PATH}" \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1

FROM uv AS build
ARG ver_markitdown
RUN uv --no-progress tool install "markitdown[all]==${ver_markitdown}"


FROM mirror.gcr.io/icecodexi/python:debian-nonroot@sha256:7f85f87ff85fa9f27689b4175ad10a42f7fc6dbe9e1c4b6447da27d5e747f1f4 AS base
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
