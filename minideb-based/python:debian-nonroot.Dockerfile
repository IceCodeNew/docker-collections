# syntax=docker/dockerfile:1

FROM mirror.gcr.io/bitnami/minideb:latest
RUN install_packages ca-certificates catatonit python3 \
    && groupadd --gid 65532 nonroot \
    && useradd --uid 65532 --gid nonroot --shell /bin/bash --create-home nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot/
