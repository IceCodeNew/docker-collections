# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/bitnami/minideb:latest AS debian-base
ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN install_packages \
        gzip isal libarchive-tools tar \
        binutils coreutils diffutils \
        ca-certificates catatonit checksec curl \
        gawk git grep \
        libcap2-bin libtree \
        parallel perl \
        sed sudo \
\
        autoconf automake \
        build-essential \
        cpp gcc g++ \
        m4 make \
        patch pkgconf \
        libc6-dev \
;
RUN mold_latest_tag_name=$(curl -sSL --fail --retry 5 --retry-delay 10 --retry-max-time 60 \
        -H 'Accept: application/vnd.github.v3+json' -- "${GITHUB_API_BASEURL:-https://api.github.com}/repos/rui314/mold/releases/latest" \
            | grep -F 'tag_name' | cut -d'"' -f4) \
    && case "$TARGETARCH" in \
        amd64) _filename="mold-${mold_latest_tag_name#v}-x86_64-linux.tar.gz"  ;; \
        arm64) _filename="mold-${mold_latest_tag_name#v}-aarch64-linux.tar.gz" ;; \
            *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && curl -sSL --fail --retry 5 --retry-delay 10 --retry-max-time 60 \
        -- "https://ghfast.top/https://github.com/rui314/mold/releases/download/${mold_latest_tag_name}/${_filename}" \
            | tar -xzf- --strip-components 1 -C /usr \
    && update-alternatives --install /usr/bin/ld ld /usr/bin/ld.mold 100 \
    && update-alternatives --auto ld

ARG CFLAGS
ARG CXXFLAGS
ENV CFLAGS="${CFLAGS:- -O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}" \
    CXXFLAGS="${CXXFLAGS:- -O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}"
ENV PKG_CONFIG="/usr/bin/pkgconf" \
    LDFLAGS="-fuse-ld=mold"
