# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM cgr.dev/chainguard/python:latest-dev@sha256:5ae128eb5c1bec2d1dbad41edf009b8cf7475e473cbf5f2bb87c4baa2ded8e7c AS assets
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
USER root:root
RUN apk update \
    && apk --no-progress --no-cache add \
        mimalloc2 snmalloc \
    && rm -rf /var/cache/apk/*

WORKDIR /emptydir/usr/lib/
RUN cp -a /usr/lib/libmimalloc-secure.so* \
          /usr/lib/libsnmalloc*.so \
          /emptydir/usr/lib/


FROM cgr.dev/chainguard/bash:latest@sha256:71101bb66f9356b0635b6ce4f1418633c0a7ca91203a5613f862f0fc27aafd47 AS bash
FROM mirror.gcr.io/icecodexi/gg:latest@sha256:c1c047f27110be76d0fae66f19c006dcd3efcd018b026770a060aa062ef1ee43            AS gg
FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:e9328168e7241e8d362094b9246d1843f901ff0106b6b7c8df42c54c7f2c9573
RUN    /usr/bin/toybox ln -sf \
    /usr/bin/toybox /usr/bin/nc \
    && /usr/bin/toybox ln -sf \
    /usr/bin/toybox /usr/bin/env

COPY --link --from=assets /emptydir/ /
COPY --link --from=gg     /ko-app/gg /usr/local/bin/
# This will break all following RUN commands
COPY --link --from=bash /usr/bin/bash /usr/bin/
