# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/library/golang:alpine AS golang-builder
ARG image_build_date=2025-12-11

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
ARG aws_lc_latest_tag=v1.65.1
ARG REPOPATH="github.com/aws/aws-lc"
WORKDIR /go/src/${REPOPATH}/
ADD --link "https://${REPOPATH}.git#${aws_lc_latest_tag}" ./

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
ENV   CFLAGS="${CFLAGS:-   -O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough -Werror=format-security -Werror=implicit -Werror=incompatible-pointer-types -Werror=int-conversion -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fexceptions -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--icf=safe}" \
    CXXFLAGS="${CXXFLAGS:- -O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough -Werror=format-security -Werror=implicit -Werror=incompatible-pointer-types -Werror=int-conversion -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fexceptions -fstrict-flex-arrays=3 -fstack-clash-protection -fstack-protector-strong -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -Wl,-z,nodlopen -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,--icf=safe}"
ENV PKG_CONFIG_ALL_STATIC=true \
    PKG_CONFIG="pkgconf --static --pure" \
    LDFLAGS="-fuse-ld=mold -static-pie"

RUN env | grep -F 'FLAGS=' \
    && ninja install \
    && strip /aws-lc-install/bin/bssl


FROM scratch
COPY --link --from=aws-lc-builder /aws-lc-install/ /aws-lc-install/
