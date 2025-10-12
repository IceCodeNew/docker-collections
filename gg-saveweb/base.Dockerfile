# syntax=docker/dockerfile:1

FROM curlimages/curl:latest AS assets
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
USER root:root
RUN apk update \
    && apk --no-progress --no-cache add \
        bash busybox-static \
        libcap-utils \
        upx \
    && rm -rf /var/cache/apk/* \
    && /bin/mv -f /bin/busybox.static /bin/busybox
RUN ln -sf /bin/busybox /bin/nc

RUN curl --fail --location https://i.jpillora.com/IceCodeNew/gg! | bash \
    && /usr/local/bin/gg --version
