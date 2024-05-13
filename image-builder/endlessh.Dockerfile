FROM icecodexi/image-builder:modern-toolbox-fedora AS build-env
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /endlessh
RUN curl -sSL "https://github.com/skeeto/endlessh/archive/refs/heads/master.tar.gz" | bsdtar -xf- --strip-components 1 \
    && sed -i -E -e 's!(CC *?=.*)!CC       = musl-gcc -static -Wl,--build-id=none!' -e 's!-Os!-O2!' Makefile \
    && make \
    && strip /endlessh/endlessh

FROM gcr.io/distroless/static:nonroot
COPY --from=build-env /endlessh/endlessh /usr/local/bin/endlessh
EXPOSE 2222/tcp
ENTRYPOINT ["/usr/local/bin/endlessh"]
CMD ["-v"]
