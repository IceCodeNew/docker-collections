# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/bitnami/minideb:bookworm@sha256:34b9499cf8d05068fe23c67245d89b234e1f31d0b6a366fa7436ebd8425df8af
# refer to: https://github.com/GoogleContainerTools/distroless/blob/f9a9ff8921bda8fda2276853804e36d2ac988b16/python3/BUILD
RUN install_packages \
        ca-certificates catatonit \
        libpython3-stdlib python3-minimal \
        python3-distutils \
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
