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
ENV   CFLAGS="${CFLAGS:-   -O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough -Werror=format-security -Werror=implicit -Werror=incompatible-pointer-types -Werror=int-conversion -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fexceptions -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--icf=all}" \
    CXXFLAGS="${CXXFLAGS:- -O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough -Werror=format-security -Werror=implicit -Werror=incompatible-pointer-types -Werror=int-conversion -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fexceptions -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--icf=all}"
ENV PKG_CONFIG="/usr/bin/pkgconf" \
    LDFLAGS="-fuse-ld=mold"
