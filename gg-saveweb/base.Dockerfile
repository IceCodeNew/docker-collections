# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM cgr.dev/chainguard/python:latest-dev@sha256:6dd180984927051df465a1914772a4675119e6a998ab9dcfbb7a9269badad387 AS assets
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


FROM cgr.dev/chainguard/bash:latest@sha256:07c96d8b819bab7d587671a862688ca8b7c9cea9075336b26a568aee4b041a14 AS bash
FROM mirror.gcr.io/icecodexi/gg:latest@sha256:e6d593daeab1359628d8db322c930b7151d117c003fc57b1dcce70a0f918c7ba            AS gg
FROM mirror.gcr.io/icecodexi/bash-toybox:latest@sha256:6ef3c0cb1de6d92026728c0d6fe1b35ae427e7493d4ea494e6de389d46dbe13a
RUN    /usr/bin/toybox ln -sf \
    /usr/bin/toybox /usr/bin/nc \
    && /usr/bin/toybox ln -sf \
    /usr/bin/toybox /usr/bin/env

COPY --link --from=assets /emptydir/ /
COPY --link --from=gg     /ko-app/gg /usr/local/bin/
# This will break all following RUN commands
COPY --link --from=bash /usr/bin/bash /usr/bin/
