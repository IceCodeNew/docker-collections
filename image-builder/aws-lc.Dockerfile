# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/library/golang:alpine AS golang-builder
ARG image_build_date=2024-06-23

RUN apk update \
    && apk --no-cache add \
        bash \
        ca-certificates curl grep sed \
        coreutils \
        binutils build-base file linux-headers \
        clang compiler-rt \
        cmake samurai \
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
ARG aws_lc_latest_tag=v1.30.1
ARG REPOPATH="github.com/aws/aws-lc"
WORKDIR /go/src/${REPOPATH}/
RUN git clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch \
        --branch "${aws_lc_latest_tag:=main}" \
        "https://${REPOPATH}" ./

ENV CC=clang \
    CXX=clang++
WORKDIR /aws-lc-build/
RUN cmake -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/aws-lc-install \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DFIPS=OFF \
        /go/src/${REPOPATH}/

ARG CFLAGS
ARG CXXFLAGS
ENV CFLAGS="${CFLAGS:- -O2 -ftree-vectorize -flto=thin -fsanitize=cfi -fvisibility=hidden -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong -fstack-clash-protection -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}" \
    CXXFLAGS="${CXXFLAGS:- -O2 -ftree-vectorize -flto=thin -fsanitize=cfi -fvisibility=hidden -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong -fstack-clash-protection -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all}"
ENV PKG_CONFIG_ALL_STATIC=true \
    PKG_CONFIG="pkgconf --static --pure" \
    LDFLAGS="-fuse-ld=mold -static-pie"

RUN env | grep -F 'FLAGS=' \
    && ninja install \
    && strip /aws-lc-install/bin/bssl


FROM scratch
COPY --link --from=aws-lc-builder /aws-lc-install/ /aws-lc-install/
