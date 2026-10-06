# syntax=mirror.gcr.io/docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

FROM mirror.gcr.io/icecodexi/image-builder:debian@sha256:40c5a4f31671534a0ca150179a9195aa0efab4506ff9819a1325160f323445b5 AS graftcp-builder
ARG TARGETARCH
ARG GOLANG_VERSION
ENV GOLANG_VERSION=${GOLANG_VERSION} \
    PATH="/usr/local/go/bin:${PATH}"
ADD --link "https://go.dev/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" /go.linux.tar.gz
RUN rm -rf /usr/local/go \
    && tar -C /usr/local/ -xzf /go.linux.tar.gz

WORKDIR /emptydir/
WORKDIR /git/graftcp/
COPY --link --from=graftcp-src . .
RUN go env -w GOFLAGS="$GOFLAGS -buildmode=pie" \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    && go env -w GOARM64=v8.2 \
    && make \
        LDFLAGS="-fuse-ld=mold -static-pie" \
        GO_LDFLAGS="-s -w -linkmode external '-extldflags=-fuse-ld=mold -static-pie'" \
    && make install \
    && install -psvD \
        /usr/local/bin/graftcp /usr/local/bin/mgraftcp \
        /emptydir/ \
    && rm -rf /git/graftcp/ /go/ /root/.cache/


FROM scratch
COPY --link --from=graftcp-builder --chmod=755 /emptydir/ /usr/local/bin/
