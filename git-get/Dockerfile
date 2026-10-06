# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/icecodexi/git-get:base@sha256:155a1610ddbfdfae8e7324ebbd78accd1c187982fa3dea8f63231864b5fbfb28
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root:root
RUN curl -fsSL -- "https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz" \
    | tar -xJf- -C /usr/ bin/git-get bin/git-gets \
    && chmod 0755 /usr/bin/git-get /usr/bin/git-gets
USER nonroot:nonroot
ENTRYPOINT [ "git" ]
CMD [ "--help" ]
