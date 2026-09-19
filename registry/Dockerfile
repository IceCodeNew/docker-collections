# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/library/registry:3.1.1@sha256:fd374bae807c225661adfe2c0c1f9970a0b8fab1761fd7dfb91e0fd9a8748f9b AS source
FROM mirror.gcr.io/icecodexi/registry:base@sha256:2bd434c923918d13757c20970e1e51702c596c42b5882558642fad761b67e65c AS assets
WORKDIR /emptydir/
COPY --from=source --chown=nonroot:nonroot /etc/distribution/ \
                   ./etc/distribution/
COPY --from=source /entrypoint.sh /bin/registry \
                   ./usr/bin/


FROM mirror.gcr.io/library/alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS catatonit
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
