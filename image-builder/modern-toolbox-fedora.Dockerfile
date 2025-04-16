# syntax=mirror.gcr.io/docker/dockerfile:1

FROM quay.io/fedora/fedora-minimal:latest AS base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG image_build_date=2024-06-23

# RUN dnf install -y --setopt=install_weak_deps=False --repo=fedora --repo=updates 'dnf-command(download)' \
#     && dnf config-manager --set-disabled fedora-cisco-openh264,fedora-modular,updates-modular \
#     && dnf -y --allowerasing install 'dnf-command(versionlock)' \
RUN microdnf -y --setopt=install_weak_deps=0 --disablerepo="*" --enablerepo=fedora --enablerepo=updates --best --nodocs install \
        gzip isa-l-tools bsdtar tar \
        binutils coreutils diffutils \
        ca-certificates catatonit checksec curl \
        gawk git-core grep \
        libcap libtree \
        parallel perl \
        sed sudo \
\
        autoconf automake \
        cpp gcc gcc-c++ \
        clang compiler-rt \
        cmake ninja-build \
        m4 make \
        mold \
        musl-clang musl-gcc musl-libc-static \
        patch pkgconf \
        zlib-ng-compat-devel zlib-ng-compat-static \
    && microdnf -y --setopt=install_weak_deps=0 --disablerepo="*" --enablerepo=fedora --enablerepo=updates --best --nodocs upgrade \
    # && dnf -y autoremove $(dnf repoquery --installonly --latest-limit=-2 -q) \
    && microdnf clean all

ARG CFLAGS
ARG CXXFLAGS
ENV CFLAGS="${CFLAGS:- -O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}" \
    CXXFLAGS="${CXXFLAGS:- -O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}"
ENV PKG_CONFIG="/usr/bin/pkgconf" \
    LDFLAGS="-fuse-ld=mold"
