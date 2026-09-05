# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM cgr.dev/chainguard/python:latest-dev@sha256:aa89119db7f7fb4a6628ac82e2c38404cc64cd56ccd858d2c78646776b3fffef AS assets
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


FROM cgr.dev/chainguard/bash:latest@sha256:817c7a483a8b9597ea7d28be7d59cdd62c9bc2a892232c202a590dac8d2026ec AS bash
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
