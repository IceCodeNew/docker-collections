# syntax=docker/dockerfile:1

FROM mirror.gcr.io/library/alpine:latest AS catatonit
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
    && rm -rf /var/cache/apk/*;


FROM mirror.gcr.io/pymumu/smartdns:latest AS smartdns
FROM cgr.dev/chainguard/static:latest
COPY --link --from=smartdns  /usr/sbin/smartdns /usr/bin/
COPY --link --from=catatonit /usr/bin/catatonit /usr/bin/

ENV TZ=Asia/Taipei
EXPOSE 53/udp
VOLUME [ "/etc/smartdns/" ]

ENTRYPOINT [ "catatonit", "--", "smartdns" ]
CMD [ "-f", "-x" ]
