# syntax=docker/dockerfile:1

FROM mirror.gcr.io/library/alpine:latest AS assets
COPY --link ./smartdns.conf /emptydir/etc/smartdns/
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
    && rm -rf /var/cache/apk/* \
    && cp -a /usr/bin/catatonit /emptydir/usr/bin/
WORKDIR /emptydir/var/smartdns/rules/


FROM mirror.gcr.io/pymumu/smartdns:latest AS smartdns
FROM cgr.dev/chainguard/static:latest
COPY --link --from=smartdns /usr/sbin/smartdns /usr/bin/
COPY --link --from=assets --chown=65532:65532  /emptydir /
VOLUME [ "/etc/smartdns/", "/var/smartdns/rules/" ]
EXPOSE 53/udp

ENV TZ=Asia/Taipei
ENTRYPOINT [ "catatonit", "--", "smartdns" ]
CMD [ "-f", "-x" ]
