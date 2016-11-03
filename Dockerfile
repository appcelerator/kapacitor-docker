FROM appcelerator/alpine:20160928
MAINTAINER Nicolas Degory <ndegory@axway.com>

ENV KAPACITOR_VERSION 1.1.0-rc2

RUN apk update && apk upgrade && \
    apk -v --virtual build-deps add --update go curl git gcc musl-dev && \
    apk add go@community && \
    go version && \
    export GOPATH=/go && \
    go get -v github.com/influxdata/kapacitor && \
    cd $GOPATH/src/github.com/influxdata/kapacitor && \
    git checkout -q --detach "v${KAPACITOR_VERSION}" && \
    python ./build.py && \
    mv ./build/kapacitor* /bin/ && \
    mkdir -p /var/lib/kapacitor && \
    apk del binutils-libs binutils gmp isl libgomp libatomic libgcc pkgconf pkgconfig mpfr3 mpc1 libstdc++ gcc go && \
    apk del build-deps && cd / && rm -rf /var/cache/apk/* $GOPATH

EXPOSE 9092

ENV INFLUXDB_URL http://localhost:8086
ENV INFLUXDB_DB telegraf
ENV INFLUXDB_RP default

ADD run.sh /run.sh
ADD kapacitor.conf /etc/kapacitor/kapacitor.conf.tpl
ADD e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl /var/lib/kapacitor/replay/e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl

VOLUME /var/lib/kapacitor

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/run.sh"]

HEALTHCHECK --interval=5s --retries=3 --timeout=1s CMD curl -I 127.0.0.1:9092/kapacitor/v1/ping | grep -q "HTTP/1.1 204 No Content"

LABEL axway_image=kapacitor
# will be updated whenever there's a new commit
LABEL commit=${GIT_COMMIT}
LABEL branch=${GIT_BRANCH}
