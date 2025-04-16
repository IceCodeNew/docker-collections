FROM mirror.gcr.io/icecodexi/image-builder:debian AS bash-builder
WORKDIR /emptydir/bin/
WORKDIR /build_root/bash/
ADD --link https://github.com/tianon/mirror-bash.git ./

ARG image_build_date=2025-04-17
RUN install_packages \
        libncurses-dev libreadline-dev
ENV PKG_CONFIG="pkgconf --static"
RUN export CFLAGS="$CFLAGS -DSYS_BASHRC='\"/etc/bash/bashrc\"'" \
    && env | grep -F 'FLAGS=' \
    && ./configure \
        --prefix=/usr --enable-static-link \
        --without-bash-malloc --disable-nls --disable-rpath \
        --without-libiconv-prefix --without-libintl-prefix \
        --enable-readline --with-installed-readline \
    && make y.tab.c && make builtins/libbuiltins.a && make \
    && ./bash --help \
    && ./bash -c 'echo hello world' | grep -qF 'hello world'
RUN ln -sf /bin/bash /emptydir/bin/sh \
    && install -Dpsv ./bash /emptydir/bin/bash


FROM mirror.gcr.io/library/alpine:latest AS musl
WORKDIR /emptydir/lib/
ARG TARGETARCH
RUN case "$TARGETARCH" in \
        amd64) cp -a /lib/ld-musl-x86_64.so.1  /lib/libc.musl-x86_64.so.1  /emptydir/lib/;; \
        arm64) cp -a /lib/ld-musl-aarch64.so.1 /lib/libc.musl-aarch64.so.1 /emptydir/lib/;; \
            *) echo "unsupported architecture"; exit 1 ;; \
    esac


FROM scratch
COPY --link --from=bash-builder /emptydir/bin/ /bin/
COPY --link --from=musl         /emptydir/lib/ /lib/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN /bin/bash --version || exit 1
