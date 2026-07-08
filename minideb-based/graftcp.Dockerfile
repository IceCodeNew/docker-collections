# syntax=mirror.gcr.io/docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

FROM mirror.gcr.io/icecodexi/image-builder:debian@sha256:e6a112ca869fb25c914f16fd04107a6c864007109b28d3ef8930230da689ae79 AS graftcp-builder
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
