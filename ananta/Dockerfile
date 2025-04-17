# syntax=docker/dockerfile:1

FROM mirror.gcr.io/icecodexi/python:debian-nonroot AS build
RUN uv tool install 'ananta[speed]'


FROM mirror.gcr.io/tianon/toybox:latest AS toybox
FROM mirror.gcr.io/bitnami/minideb:latest AS assets
COPY --link --from=toybox /usr/bin/ /emptydir/usr/bin/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN rm -f /emptydir/usr/bin/bash /emptydir/usr/bin/sh \
    && install_packages \
        bash-static \
        catatonit \
    && cp -af /bin/bash-static   /emptydir/usr/bin/bash \
    && ln -sf /usr/bin/bash      /emptydir/usr/bin/sh \
    && cp -af /usr/bin/catatonit /emptydir/usr/bin/


FROM gcr.io/distroless/python3:latest
COPY --link --chmod=0755 ./docker-entrypoint.sh /usr/local/bin/
# toybox + bash(ash) + catatonit
COPY --link --from=assets /emptydir/            /
COPY --link --from=build  /home/nonroot/.local/ /home/nonroot/.local/

SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
RUN rm -rf /bin/ && ln -sf /usr/bin /bin

USER nonroot:nonroot
WORKDIR /home/nonroot/
ENV TZ=Asia/Taipei
ENV PATH="/home/nonroot/.local/bin:${PATH}"

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
