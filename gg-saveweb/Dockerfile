# syntax=docker/dockerfile:1

FROM icecodexi/gg-saveweb:base           AS assets
FROM icecodexi/saveweb:acfunction        AS acfun
FROM icecodexi/saveweb:aixifan_videoinfo AS aixifan
FROM icecodexi/saveweb:lowapk-v3         AS lowapk

FROM cgr.dev/chainguard/python:latest-dev
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root:root
RUN apk update \
    && apk --no-progress --no-cache add \
        mimalloc2 \
        snmalloc \
    && apk --no-progress --no-cache upgrade \
    && rm -rf /var/cache/apk/*;
ENV TZ=Asia/Taipei
ENV LD_PRELOAD=/usr/lib/libsnmallocshim-checks.so
ENV PYTHONUNBUFFERED=x

COPY --link --chmod=755   ./entrypoint.sh /home/nonroot/
COPY --link --from=assets /bin/           /bin/
COPY --link --from=assets /usr/local/bin/ /usr/local/bin/

COPY --link --from=acfun   --chown=65532:65532 \
    /ko-app/       /ko-app/
COPY --link --from=aixifan --chown=65532:65532 \
    /home/nonroot/ /home/nonroot/
COPY --link --from=lowapk  --chown=65532:65532 \
    /home/nonroot/ /home/nonroot/

WORKDIR /var/run/ko/
WORKDIR /home/nonroot/
# docker run --cap-add=SYS_PTRACE --user root:root
ENTRYPOINT [ "/home/nonroot/entrypoint.sh" ]
CMD [ "/ko-app/acdanmaku", "/home/nonroot/.local/bin/lowapk" ]
