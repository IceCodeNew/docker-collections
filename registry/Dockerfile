# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/library/registry:2 AS source
FROM icecodexi/registry:base AS assets
WORKDIR /emptydir/
COPY --from=source --chown=nonroot:nonroot /etc/docker/registry/ \
                   ./etc/docker/registry/
COPY --from=source /entrypoint.sh /bin/registry \
                   ./usr/bin/


FROM icecodexi/registry:base
COPY --link --from=assets /emptydir/ /

VOLUME ["/var/lib/registry"]
EXPOSE 5000

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

CMD ["/etc/docker/registry/config.yml"]
