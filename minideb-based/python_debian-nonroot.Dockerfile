# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/bitnami/minideb:latest@sha256:05a289d4bcdbeb2b9d9bf1070c3fcf7d1ba3dfb7fbff4d26f28d6eecfa3b7b02
# refer to: https://github.com/GoogleContainerTools/distroless/blob/f9a9ff8921bda8fda2276853804e36d2ac988b16/python3/BUILD
RUN install_packages \
        ca-certificates catatonit \
        extrepo \
        libpython3-stdlib python3-minimal \
        tzdata \
        zlib1g \
\
        libbz2-1.0 \
        libcom-err2 \
        libcrypt1 \
        libdb5.3 \
        libexpat1 \
        libffi8 \
        libgssapi-krb5-2 \
        libk5crypto3 \
        libkeyutils1 \
        libkrb5-3 \
        libkrb5support0 \
        liblzma5 \
        libncursesw6 \
        libnsl2 \
        libreadline8 \
        libsqlite3-0 \
        libtinfo6 \
        libtirpc3 \
        libuuid1 \
    && groupadd --gid 65532 nonroot \
    && useradd --uid 65532 --gid nonroot --shell /bin/bash --create-home nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot/
