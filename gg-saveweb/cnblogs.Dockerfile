# syntax=docker/dockerfile:1

FROM icecodexi/gg-saveweb:base AS assets
FROM icecodexi/saveweb:cnblogs
COPY --link --chmod=755   ./entrypoint.sh /home/nonroot/
COPY --link --from=assets /bin/           /bin/
COPY --link --from=assets /usr/local/bin/ /usr/local/bin/

ENTRYPOINT [ "/home/nonroot/entrypoint.sh" ]
CMD [ "/ko-app/cnblogs_posts_list" ]
