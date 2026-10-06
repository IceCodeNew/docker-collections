# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/library/registry:3.1.2@sha256:ddf754342cfc8acc51a56d5d0ab6af06826461864460636d8bd5c546dab2a7b8 AS source
FROM mirror.gcr.io/icecodexi/registry:base@sha256:2bd434c923918d13757c20970e1e51702c596c42b5882558642fad761b67e65c AS assets
WORKDIR /emptydir/
COPY --from=source --chown=nonroot:nonroot /etc/distribution/ \
                   ./etc/distribution/
COPY --from=source /entrypoint.sh /bin/registry \
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
