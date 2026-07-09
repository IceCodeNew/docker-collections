# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/icecodexi/git-get:base@sha256:05aeaae41772d0248d3b0d8e7d84e563ef75879c168824126ad7431618cd1f11
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root:root
RUN curl -fsSL -- "https://github.com/b1f6c1c4/git-get/releases/latest/download/git-get.tar.xz" \
    | tar -xJf- -C /usr/ bin/git-get bin/git-gets \
    && chmod 0755 /usr/bin/git-get /usr/bin/git-gets
USER nonroot:nonroot
ENTRYPOINT [ "git" ]
CMD [ "--help" ]
