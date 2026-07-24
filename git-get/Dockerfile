# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/icecodexi/git-get:base@sha256:155a1610ddbfdfae8e7324ebbd78accd1c187982fa3dea8f63231864b5fbfb28
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root:root
RUN curl -fsSL -- "https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz" \
    | tar -xJf- -C /usr/ bin/git-get bin/git-gets \
    && chmod 0755 /usr/bin/git-get /usr/bin/git-gets
USER nonroot:nonroot
ENTRYPOINT [ "git" ]
CMD [ "--help" ]
