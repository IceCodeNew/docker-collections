# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/tianon/toybox:0.8.14@sha256:a16f8b5944fecf41840b122147588dd63e7e3e1d07ed2a0913aba2118ca91ccb AS toybox
FROM mirror.gcr.io/bitnami/minideb:trixie@sha256:aa0c770c20ad7d7259e53ef6088768fba320aecc64bc343bcaea121b76189686 AS assets
COPY --link --from=toybox /usr/bin/  /emptydir/usr/bin/
COPY --link --from=toybox /usr/sbin/ /emptydir/usr/sbin/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN rm -f /emptydir/usr/bin/bash /emptydir/usr/bin/sh \
    && install_packages \
        bash-static \
        catatonit \
    && cp -af /usr/bin/bash-static /emptydir/usr/bin/bash \
    && ln -sf /usr/bin/bash        /emptydir/usr/bin/sh \
    && cp -af /usr/bin/catatonit   /emptydir/usr/bin/


FROM scratch
COPY --link --from=assets /emptydir/ /
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
