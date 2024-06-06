# syntax=docker/dockerfile:1

FROM registry:2 AS source
FROM icecodexi/registry:base AS assets
WORKDIR /emptydir/
COPY --from=source /entrypoint.sh /bin/registry \
                   ./bin/
COPY --from=source --chown=nonroot:nonroot /etc/docker/registry/ \
                   ./etc/docker/registry/


FROM icecodexi/registry:base
COPY --link --from=assets /emptydir/ /

VOLUME ["/var/lib/registry"]
EXPOSE 5000

ENTRYPOINT ["/bin/entrypoint.sh"]

CMD ["/etc/docker/registry/config.yml"]
