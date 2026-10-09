# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/tianon/toybox:0.8.14@sha256:8fe8776eca4b6dabdee10f3522ae0ab9c51dbac70aaff9dfd377eac548f8e7f7 AS toybox
FROM mirror.gcr.io/bitnami/minideb:bookworm@sha256:6dbae03dd15f744121218932396269199639042141966e45b934254e757782bb AS assets
COPY --link --parents --from=toybox /./usr/bin/ /./usr/sbin/ /emptydir/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN rm -f /emptydir/usr/bin/bash /emptydir/usr/bin/sh \
    && install_packages \
        bash-static \
        catatonit \
    && cp -af /bin/bash-static     /emptydir/usr/bin/bash \
    && ln -sf /usr/bin/bash        /emptydir/usr/bin/sh \
    && cp -af /usr/bin/catatonit   /emptydir/usr/bin/


FROM scratch
COPY --link --from=assets /emptydir/ /
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
