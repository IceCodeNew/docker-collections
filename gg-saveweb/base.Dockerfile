# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM cgr.dev/chainguard/python:latest-dev@sha256:630df1be3733f7b38d1b535872904248adfe23fbea4befcb08da47cb7436ddb2 AS assets
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


FROM cgr.dev/chainguard/bash:latest@sha256:3a5a750e5d21d5de8b7341167cae5104da0004bf10c08844e9486342ad42d0f6 AS bash
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
