# syntax=docker/dockerfile:1

FROM mirror.gcr.io/bitnami/minideb:latest
# refer to: https://github.com/GoogleContainerTools/distroless/blob/f9a9ff8921bda8fda2276853804e36d2ac988b16/python3/BUILD
RUN install_packages \
        ca-certificates catatonit \
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
