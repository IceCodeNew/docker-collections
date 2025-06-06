# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/icecodexi/image-builder:modern-toolbox-fedora AS build-env
WORKDIR /endlessh
RUN curl -sSL "https://github.com/skeeto/endlessh/archive/refs/heads/master.tar.gz" | bsdtar -xf- --strip-components 1 \
    && sed -i -E -e 's!(CC *?=.*)!CC       = musl-gcc -static!' -e 's!-Os!-O2 -fhardened!' Makefile \
    && make \
    && strip /endlessh/endlessh


FROM mirror.gcr.io/icecodexi/bash-toybox:latest AS catatonit
FROM gcr.io/distroless/static:nonroot
COPY --link --from=build-env --chmod=755 /endlessh/endlessh /usr/local/bin/
COPY --link --from=catatonit             /usr/bin/catatonit /usr/bin/
EXPOSE 2222/tcp
ENTRYPOINT [ "catatonit", "--", "endlessh" ]
CMD ["-v"]
