# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM cgr.dev/chainguard/python:latest-dev@sha256:8b26e872c43d11dfc685daa9266bfba420b2e51d8c3a8ee5d4d817160e7c0d56 AS assets
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


FROM cgr.dev/chainguard/bash:latest@sha256:8036c169c6ebfd3c59fc8609e18b399e0506eab82a505b774f354bec107a3c4d AS bash
FROM mirror.gcr.io/icecodexi/gg:latest@sha256:e6d593daeab1359628d8db322c930b7151d117c003fc57b1dcce70a0f918c7ba            AS gg
FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:307abe6c09de20cc78544fe645d7d31f0f756540e83b52f6fb59dbce447ead80
RUN    /usr/bin/toybox ln -sf \
    /usr/bin/toybox /usr/bin/nc \
    && /usr/bin/toybox ln -sf \
    /usr/bin/toybox /usr/bin/env

COPY --link --from=assets /emptydir/ /
COPY --link --from=gg     /ko-app/gg /usr/local/bin/
# This will break all following RUN commands
COPY --link --from=bash /usr/bin/bash /usr/bin/
