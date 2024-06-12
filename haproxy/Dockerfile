# syntax=docker/dockerfile:1

FROM icecodexi/image-builder:alpine AS step0_prepare
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG image_build_date='2024-05-28'

## pre-defined envs
# ENV LANG=C.UTF-8 \
#     LC_ALL=C.UTF-8
# ENV PKG_CONFIG="/usr/bin/pkgconf" \
#     LDFLAGS="-fuse-ld=mold" \
#     CFLAGS="-O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all" \
#     CXXFLAGS="-O2 -ftree-vectorize -pipe -D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong ${protect_branch} ${CPU_CFLAGS} -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all"

RUN apk update \
    && apk --no-progress --no-cache add \
        lua5.4-dev \
        pcre2-dev \
        jemalloc-dev jemalloc-static \
        scudo-malloc-dev scudo-malloc-static \
    && apk --no-progress --no-cache upgrade \
    && rm -f /usr/lib/lua5.4/liblua.so \
    && rm -rf /var/cache/apk/*
COPY --link --from=icecodexi/image-builder:aws-lc /aws-lc-install/ /usr/local/


FROM step0_prepare AS haproxy
ARG haproxy_branch=3.0
ARG dockerfile_workdir=/build_root/haproxy/
WORKDIR "$dockerfile_workdir"
RUN unset -f curl \
    && eval 'curl() { /usr/bin/curl -LRq --retry 5 --retry-delay 10 --retry-max-time 60 --fail "$@"; }' \
    && curl -sSL "https://git.haproxy.org/?p=haproxy-${haproxy_branch}.git;a=snapshot;h=refs/heads/master;sf=tgz" \
        | bsdtar -xf- --strip-components 1 --no-xattrs

ENV PKG_CONFIG_ALL_STATIC=true \
    PKG_CONFIG="pkgconf --static --pure"
ARG TARGETARCH
RUN case "$TARGETARCH" in \
        amd64) export protect_branch="-fcf-protection=full"; \
               export CPU_CFLAGS="-march=x86-64-v2";; \
        arm64) export protect_branch="-mbranch-protection=standard"; \
               export CPU_CFLAGS="-march=armv8.1-a+crypto";; \
            *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && make -j "$(nproc)" TARGET=linux-musl \
        USE_PCRE2_JIT=1 USE_STATIC_PCRE2=1 \
        USE_OPENSSL_AWSLC=1 SSL_INC="/usr/local/include/openssl" SSL_LIB="/usr/local/lib" \
        USE_PROMEX=1 \
        USE_LUA=1 LUA_INC=/usr/include/lua5.4 LUA_LIB=/usr/lib/lua5.4 \
        USE_PIE=1 USE_STACKPROTECTOR=1 USE_RELRO_NOW=1 \
        CC=clang-18 CXX=clang++-18 \
        ARCH_FLAGS="-flto=thin" \
        OPT_CFLAGS="-O2 -ftree-vectorize" \
        CPU_CFLAGS="$CPU_CFLAGS" \
        DEFINE="-D_FORTIFY_SOURCE=2 -fexceptions -fstack-clash-protection -fstack-protector-strong ${protect_branch}" \
        ADDLIB="-Wl,-Bstatic -L/usr/lib -ljemalloc_pic -Wl,-Bdynamic" \
        V=1 \
    && strip -o /haproxy ./haproxy

RUN readelf -p .comment /haproxy \
    && libtree -vvv /haproxy


FROM haproxy:3.0-alpine AS assets
USER root
RUN apk update \
    && apk --no-progress --no-cache add \
        tzdata \
    && apk --no-progress --no-cache upgrade \
    && rm -rf /var/cache/apk/*

COPY --link --from=haproxy --chmod=755 /haproxy /usr/local/sbin/
USER haproxy
# smoke test
RUN /usr/local/sbin/haproxy -vv


FROM scratch
COPY --link --from=assets / /

ENV TZ=Asia/Taipei

STOPSIGNAL SIGUSR1

ENTRYPOINT ["docker-entrypoint.sh"]

USER haproxy

# https://github.com/docker-library/haproxy/issues/200
WORKDIR /var/lib/haproxy

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
