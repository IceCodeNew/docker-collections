# syntax=mirror.gcr.io/docker/dockerfile:1

FROM icecodexi/git-get:base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root:root
RUN curl -fsSL -- "https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz" \
    | tar -xJf- -C /usr/ bin/git-get bin/git-gets \
    && chmod 0755 /usr/bin/git-get /usr/bin/git-gets
USER nonroot:nonroot
ENTRYPOINT [ "git" ]
CMD [ "--help" ]
