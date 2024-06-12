# syntax=docker/dockerfile:1

FROM icecodexi/image-builder:alpine AS golang-builder

# don't auto-upgrade the gotoolchain
# https://github.com/docker-library/golang/issues/472
ENV GOTOOLCHAIN=local

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
COPY --from=golang:alpine --link /usr/local/go/ /usr/local/go/
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 1777 "$GOPATH"
WORKDIR $GOPATH
# FROM golang:alpine AS golang-builder


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
        clang18 compiler-rt \
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
ARG aws_lc_latest_tag='v1.28.0'
ARG REPOPATH="github.com/aws/aws-lc"
WORKDIR /go/src/${REPOPATH}/
RUN git clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch \
        --branch "${aws_lc_latest_tag:=main}" \
        "https://${REPOPATH}" ./

ENV CC=clang-18 \
    CXX=clang++-18
WORKDIR /aws-lc-build/
RUN unset LDFLAGS CFLAGS CXXFLAGS \
    && cmake -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/aws-lc-install \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DFIPS=OFF \
        /go/src/${REPOPATH}/

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
ENV  LDFLAGS="-fuse-ld=mold -static-pie" \
      CFLAGS="-O2 -ftree-vectorize -flto=thin -fsanitize=cfi -fvisibility=hidden -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong -fstack-clash-protection ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all" \
    CXXFLAGS="-O2 -ftree-vectorize -flto=thin -fsanitize=cfi -fvisibility=hidden -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong -fstack-clash-protection ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all"
RUN env \
    && ninja install \
    && strip /aws-lc-install/bin/bssl


FROM scratch
COPY --link --from=aws-lc-builder /aws-lc-install/ /aws-lc-install/
