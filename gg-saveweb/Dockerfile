# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/icecodexi/gg-saveweb:base@sha256:926fc4daa9454f899b4ce92267280c595ac877c15a40be441af7930aed65bd70           AS assets
FROM mirror.gcr.io/icecodexi/saveweb:acfunction@sha256:6e38fa7cbfc2a28f0c533a09ba43776cfff27a5a8e5d334b501f46a9cc3db0ab        AS acfun
FROM mirror.gcr.io/icecodexi/saveweb:aixifan_videoinfo@sha256:5a0a45b86f54a42389df2691f6ff3c1feba470405a5dbab457f0038c82def182 AS aixifan
FROM mirror.gcr.io/icecodexi/saveweb:lowapk-v3@sha256:940117edbd615069d36f9867f4b239bb9f621edc96208d7aed40e0de0f409f9b         AS lowapk
FROM cgr.dev/chainguard/python:latest@sha256:8c6e0d0a587455e8a8d145e20234d5ef5a531a1c052a7b9d76b155ccc7fcded2
COPY --link --from=assets /              /
COPY --link --chmod=755  ./entrypoint.sh /home/nonroot/
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
USER root:root

ENV TZ=Asia/Taipei
ENV LD_PRELOAD=/usr/lib/libsnmallocshim-checks.so
ENV PYTHONUNBUFFERED=x

COPY --link --from=acfun   --chown=65532 \
    /ko-app/       /ko-app/
COPY --link --from=aixifan --chown=65532 \
    /home/nonroot/ /home/nonroot/
COPY --link --from=lowapk  --chown=65532 \
    /home/nonroot/ /home/nonroot/

WORKDIR /var/run/ko/
WORKDIR /home/nonroot/
# docker run --cap-add=SYS_PTRACE --user root:root
ENTRYPOINT [ "catatonit", "--", "/home/nonroot/entrypoint.sh" ]
CMD [ "/ko-app/acdanmaku", "/home/nonroot/.local/bin/lowapk" ]
