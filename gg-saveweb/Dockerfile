# syntax=docker/dockerfile:1

FROM icecodexi/gg-saveweb:base           AS assets
FROM icecodexi/saveweb:acfunction        AS acfun
FROM icecodexi/saveweb:aixifan_videoinfo AS aixifan
FROM icecodexi/saveweb:lowapk-v3         AS lowapk
FROM cgr.dev/chainguard/python:latest
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
