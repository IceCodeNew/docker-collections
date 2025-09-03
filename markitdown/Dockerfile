# syntax=docker/dockerfile:1

FROM mirror.gcr.io/icecodexi/python:debian-nonroot
ENV EXIFTOOL_PATH=/usr/bin/exiftool \
    FFMPEG_PATH=/usr/bin/ffmpeg
ARG DEBIAN_FRONTEND=noninteractive
USER root:root
RUN install_packages \
        exiftool ffmpeg \
        pipx
USER nonroot:nonroot

ARG ver_markitdown
RUN pipx ensurepath \
    && pipx install "markitdown[all]==${ver_markitdown}" --pip-args="--no-cache-dir"

ENV PATH="/home/nonroot/.local/bin:${PATH}"
ENTRYPOINT [ "catatonit", "-g", "--", "markitdown" ]
