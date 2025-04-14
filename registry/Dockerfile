# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/library/registry:2 AS source
FROM icecodexi/registry:base AS assets
WORKDIR /emptydir/
COPY --from=source --chown=nonroot:nonroot /etc/docker/registry/ \
                   ./etc/docker/registry/
COPY --from=source /entrypoint.sh /bin/registry \
                   ./usr/bin/


FROM mirror.gcr.io/library/alpine:latest AS catatonit
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
    && rm -rf /var/cache/apk/*;


FROM icecodexi/registry:base
COPY --link --from=assets    /emptydir/         /
COPY --link --from=catatonit /usr/bin/catatonit /usr/bin/

VOLUME ["/var/lib/registry"]
EXPOSE 5000

ENTRYPOINT [ "catatonit", "--", "/usr/bin/entrypoint.sh" ]

CMD [ "/etc/docker/registry/config.yml" ]
