# syntax=docker/dockerfile:1

FROM icecodexi/gg-saveweb:base AS assets
FROM icecodexi/saveweb:huashijie
COPY --link --from=assets /usr/local/bin/ /usr/local/bin/
COPY --link --chmod=755  ./entrypoint.sh  /
ENTRYPOINT /entrypoint.sh
CMD [ "/ko-app/huashijie_work_go" ]
