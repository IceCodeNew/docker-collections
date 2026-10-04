# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/tianon/toybox:0.8.14@sha256:8fe8776eca4b6dabdee10f3522ae0ab9c51dbac70aaff9dfd377eac548f8e7f7 AS toybox
FROM mirror.gcr.io/bitnami/minideb:trixie@sha256:635d5c929e73d70974aaf9fbf9bab835efa33caa3a888da7887e004e80a4f882 AS assets
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
