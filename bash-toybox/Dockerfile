# syntax=docker/dockerfile:1

FROM mirror.gcr.io/tianon/toybox:latest AS toybox
FROM mirror.gcr.io/bitnami/minideb:latest AS assets
COPY --link --from=toybox /usr/bin/  /emptydir/usr/bin/
COPY --link --from=toybox /usr/sbin/ /emptydir/usr/sbin/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN rm -f /emptydir/usr/bin/bash /emptydir/usr/bin/sh \
    && install_packages \
        bash-static \
        catatonit \
    && cp -af /bin/bash-static   /emptydir/usr/bin/bash \
    && ln -sf /usr/bin/bash      /emptydir/usr/bin/sh \
    && cp -af /usr/bin/catatonit /emptydir/usr/bin/


FROM scratch
COPY --link --from=assets /emptydir/ /
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
