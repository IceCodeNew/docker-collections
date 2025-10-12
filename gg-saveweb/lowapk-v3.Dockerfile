# syntax=docker/dockerfile:1

FROM icecodexi/gg-saveweb:base AS assets
FROM icecodexi/saveweb:lowapk-v3
COPY --link --chmod=755   ./entrypoint.sh /home/nonroot/
COPY --link --from=assets /bin/           /bin/
COPY --link --from=assets /usr/local/bin/ /usr/local/bin/

# docker run --cap-add=SYS_PTRACE
USER root:root
ENTRYPOINT [ "/home/nonroot/entrypoint.sh" ]
CMD [ "/home/nonroot/.local/bin/lowapk" ]
