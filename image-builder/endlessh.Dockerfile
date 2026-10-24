# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/icecodexi/image-builder:modern-toolbox-fedora@sha256:cf9fea3fe9ad18316af391e0ae07d5480da1fa0cc9fa106e98cf58590a373cdc AS build-env
WORKDIR /endlessh
RUN curl -sSL "https://github.com/skeeto/endlessh/archive/refs/heads/master.tar.gz" | bsdtar -xf- --strip-components 1 \
    && sed -i -E -e 's!(CC *?=.*)!CC       = musl-gcc -static!' -e 's!-Os!-O2 -fhardened!' Makefile \
    && make \
    && strip /endlessh/endlessh


FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:e9328168e7241e8d362094b9246d1843f901ff0106b6b7c8df42c54c7f2c9573 AS catatonit
FROM gcr.io/distroless/static:nonroot@sha256:18f4cc26c9ffa7f20a359298be7deadac5c607c8e03a02b8119f1a5fc2f82c99
COPY --link --from=build-env --chmod=755 /endlessh/endlessh /usr/local/bin/
COPY --link --from=catatonit             /usr/bin/catatonit /usr/bin/
EXPOSE 2222/tcp
ENTRYPOINT [ "catatonit", "--", "endlessh" ]
CMD ["-v"]
