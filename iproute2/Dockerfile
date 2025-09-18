# syntax=docker/dockerfile:1

FROM mirror.gcr.io/icecodexi/image-builder:alpine AS build
RUN apk update \
    && apk --no-progress --no-cache add \
        bison flex \
    && rm -rf /var/cache/apk/*;

ARG iproute2_latest_tag=v6.16.0
ARG REPOPATH="github.com/iproute2/iproute2"
ADD --link "https://${REPOPATH}.git#${iproute2_latest_tag}" /src/${REPOPATH}/
WORKDIR /src/${REPOPATH}/

ARG SBINDIR=/output/sbin
ARG SHARED_LIBS=n
RUN ./configure \
    && make SHARED_LIBS="${SHARED_LIBS}" SBINDIR="${SBINDIR}" install

RUN mkdir -p /output/bin/ /output/lib/ /output/test/ \
    && ln -sf /bin/busybox /output/bin/cp \
    && ln -sf /bin/busybox /output/bin/ls \
    && ln -sf /bin/busybox /output/bin/rm \
    && ln -sf /bin/busybox /output/bin/sh \
    && cp -af /bin/busybox /output/bin/busybox \
    && cp -af /lib/*musl* /usr/lib/libgcc_s.so* \
                          /output/lib/ \
    && for cmd in $(ls -1 "${SBINDIR}"); do \
        ln -f "${SBINDIR}/${cmd}" "/output/test/${cmd}"; \
    done


FROM scratch AS bin-test
COPY --link --from=build /output/ /
SHELL ["/bin/sh", "-eo", "pipefail", "-c"]
RUN /bin/rm -f \
        /test/ctstat /test/rtstat /test/routel; \
    for cmd in $(ls -1 /test/); do \
        if [[ "${cmd}" = "lnstat" ]]; then \
            "/test/${cmd}" -h || exit 1; \
        else \
            "/test/${cmd}" -V || exit 1; \
        fi; \
    done; \
    /bin/rm -rf /bin/ /test/;
