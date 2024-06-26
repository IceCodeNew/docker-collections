# syntax=docker/dockerfile:1

FROM curlimages/curl:latest AS assets
ADD --link "https://raw.githubusercontent.com/mzz2017/gg/main/release/go.sh" /gg.sh
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
USER root:root
RUN apk update \
    && apk --no-progress --no-cache add \
        busybox-static \
        libcap-utils \
        upx \
    && apk --no-progress --no-cache upgrade \
    && rm -rf /var/cache/apk/* \
    && /bin/mv -f /bin/busybox.static /bin/busybox
RUN ln -sf /bin/busybox /bin/nc

# fix: check_command failed
RUN sh -x /gg.sh || true
RUN upx -d /usr/local/bin/gg \
    && /usr/local/bin/gg --version
