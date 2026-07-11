# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/icecodexi/image-builder:modern-toolbox-fedora@sha256:cf9fea3fe9ad18316af391e0ae07d5480da1fa0cc9fa106e98cf58590a373cdc AS build-env
WORKDIR /endlessh
RUN curl -sSL "https://github.com/skeeto/endlessh/archive/refs/heads/master.tar.gz" | bsdtar -xf- --strip-components 1 \
    && sed -i -E -e 's!(CC *?=.*)!CC       = musl-gcc -static!' -e 's!-Os!-O2 -fhardened!' Makefile \
    && make \
    && strip /endlessh/endlessh


FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:307abe6c09de20cc78544fe645d7d31f0f756540e83b52f6fb59dbce447ead80 AS catatonit
FROM gcr.io/distroless/static:nonroot@sha256:d29e660cc75a5b6b1334e03c5c81ccf9bc0884a002c6000dbf0fb96034814478
COPY --link --from=build-env --chmod=755 /endlessh/endlessh /usr/local/bin/
COPY --link --from=catatonit             /usr/bin/catatonit /usr/bin/
EXPOSE 2222/tcp
ENTRYPOINT [ "catatonit", "--", "endlessh" ]
CMD ["-v"]
