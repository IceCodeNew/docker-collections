# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/icecodexi/gg-saveweb:base@sha256:48945a96c93772cf9fe0ff52ad39004683eedebbf867a13c092e3e9d80d51d7a           AS assets
FROM mirror.gcr.io/icecodexi/saveweb:acfunction@sha256:6e38fa7cbfc2a28f0c533a09ba43776cfff27a5a8e5d334b501f46a9cc3db0ab        AS acfun
FROM mirror.gcr.io/icecodexi/saveweb:aixifan_videoinfo@sha256:5a0a45b86f54a42389df2691f6ff3c1feba470405a5dbab457f0038c82def182 AS aixifan
FROM mirror.gcr.io/icecodexi/saveweb:lowapk-v3@sha256:940117edbd615069d36f9867f4b239bb9f621edc96208d7aed40e0de0f409f9b         AS lowapk
FROM cgr.dev/chainguard/python:latest@sha256:4d908c6a44ba22460e34a2f6dd665b8fcb82bd3e6c887e749bd6fef243e10094
COPY --link --from=assets /              /
COPY --link --chmod=755  ./entrypoint.sh /home/nonroot/
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
USER root:root

ENV TZ=Asia/Taipei
ENV LD_PRELOAD=/usr/lib/libsnmallocshim-checks.so
ENV PYTHONUNBUFFERED=x

COPY --link --from=acfun   --chown=65532:65532 \
    /ko-app/       /ko-app/
COPY --link --from=aixifan --chown=65532:65532 \
    /home/nonroot/ /home/nonroot/
COPY --link --from=lowapk  --chown=65532:65532 \
    /home/nonroot/ /home/nonroot/

WORKDIR /var/run/ko/
WORKDIR /home/nonroot/
# docker run --cap-add=SYS_PTRACE --user root:root
ENTRYPOINT [ "catatonit", "--", "/home/nonroot/entrypoint.sh" ]
CMD [ "/ko-app/acdanmaku", "/home/nonroot/.local/bin/lowapk" ]
