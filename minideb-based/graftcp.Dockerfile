# syntax=mirror.gcr.io/docker/dockerfile:1

FROM mirror.gcr.io/icecodexi/image-builder:debian AS graftcp-builder
ARG TARGETARCH
ENV GOLANG_VERSION=1.24.2 \
    PATH="/usr/local/go/bin:${PATH}"
ADD --link "https://go.dev/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" /go.linux.tar.gz
RUN rm -rf /usr/local/go \
    && tar -C /usr/local/ -xzf /go.linux.tar.gz

WORKDIR /emptydir/
WORKDIR /git/graftcp/
ADD --link "https://github.com/hmgle/graftcp.git" ./
RUN go env -w GOFLAGS="$GOFLAGS -buildmode=pie" \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    && make \
        LDFLAGS="-fuse-ld=mold -static-pie" \
        GO_LDFLAGS="-s -w -linkmode external '-extldflags=-fuse-ld=mold -static-pie'" \
    && make install \
    && install -psvD \
        /usr/local/bin/graftcp /usr/local/bin/graftcp-local /usr/local/bin/mgraftcp \
        /emptydir/ \
    && rm -rf /git/graftcp/ /go/ /root/.cache/


FROM scratch
COPY --link --from=graftcp-builder --chmod=755 /emptydir/ /usr/local/bin/
