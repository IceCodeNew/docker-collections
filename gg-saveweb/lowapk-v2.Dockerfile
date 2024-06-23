# syntax=docker/dockerfile:1

FROM icecodexi/gg-saveweb:base AS assets
FROM icecodexi/saveweb:lowapk-v2
COPY --link --from=assets /usr/local/bin/ /usr/local/bin/
COPY --link --chmod=755  ./entrypoint.sh  /
ENTRYPOINT /entrypoint.sh
CMD [ "python3", "/home/nonroot/.venv/bin/lowapk_v2" ]
