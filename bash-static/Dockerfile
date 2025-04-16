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


FROM scratch
COPY --link --from=bash-builder /emptydir/bin/ /bin/
RUN /bin/bash --version || exit 1
