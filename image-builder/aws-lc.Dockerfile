# syntax=docker/dockerfile:1

FROM golang:alpine AS golang-builder
ARG image_build_date='2024-05-11'
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apk update \
    && apk --no-cache add \
        bash \
        ca-certificates curl grep sed \
        coreutils \
        binutils build-base file linux-headers \
        clang compiler-rt \
        cmake ninja-build ninja-is-really-ninja \
        git \
        libarchive-tools \
        mold \
        musl musl-dev musl-libintl musl-utils \
        perl \
        pkgconf \
    && apk --no-cache upgrade \
    && rm -rf /var/cache/apk/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV CGO_ENABLED=0


FROM golang-builder AS aws-lc-builder
ARG aws_lc_latest_tag='v1.28.0'
ARG REPOPATH="github.com/aws/aws-lc"
WORKDIR /go/src/${REPOPATH}/
RUN git clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch \
        --branch "${aws_lc_latest_tag:=main}" \
        "https://${REPOPATH}" ./

ARG TARGETARCH
RUN case "$TARGETARCH" in \
        amd64) export protect_branch="-fcf-protection=full"; \
               export CPU_CFLAGS="-march=x86-64-v2";; \
        arm64) export protect_branch="-mbranch-protection=standard"; \
               export CPU_CFLAGS="-march=armv8.1-a+crypto";; \
            *) echo "unsupported architecture"; exit 1 ;; \
    esac
ENV PKG_CONFIG_ALL_STATIC=true \
    PKG_CONFIG="pkgconf --static --pure"
ENV CC=clang \
    CXX=clang++ \
    LDFLAGS="-fuse-ld=mold -static-pie" \
    CFLAGS="-O2 -ftree-vectorize -flto=thin -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches" \
    CXXFLAGS="-O2 -ftree-vectorize -flto=thin -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches"
# wait for compiler-rt upgraded to 18.x
#   -fstack-clash-protection
#   -fsanitize=cfi -fvisibility=hidden 
# do not use:
#   -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all

WORKDIR /aws-lc-build/
RUN env \
    && cmake -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/aws-lc-install \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DFIPS=OFF \
        /go/src/${REPOPATH}/ \
    && ninja install \
    && strip /aws-lc-install/bin/bssl


FROM scratch
COPY --link --from=aws-lc-builder /aws-lc-install/ /aws-lc-install/
