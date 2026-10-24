# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/library/registry:3.1.2@sha256:01cd312e67026f06f5d89c3e133a4a9adc7cb9eeb9b1194e0b2954dfd770efd2 AS source
FROM mirror.gcr.io/icecodexi/registry:base@sha256:2bd434c923918d13757c20970e1e51702c596c42b5882558642fad761b67e65c AS assets
WORKDIR /emptydir/
COPY --link --from=source --chown=65532 /etc/distribution/ \
                   ./etc/distribution/
COPY --link --from=source /entrypoint.sh /bin/registry \
                   ./usr/bin/


FROM mirror.gcr.io/library/alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS catatonit
RUN apk update \
    && apk --no-progress --no-cache add \
        catatonit \
    && rm -rf /var/cache/apk/*;


FROM mirror.gcr.io/icecodexi/registry:base@sha256:2bd434c923918d13757c20970e1e51702c596c42b5882558642fad761b67e65c
COPY --link --from=assets    /emptydir/         /
COPY --link --from=catatonit /usr/bin/catatonit /usr/bin/

VOLUME ["/var/lib/registry"]
EXPOSE 5000

ENTRYPOINT [ "catatonit", "--", "/usr/bin/entrypoint.sh" ]

CMD [ "/etc/distribution/config.yml" ]
