FROM appcelerator/alpine:20160726
MAINTAINER Nicolas Degory <ndegory@axway.com>

ENV KAPACITOR_VERSION 0.13.1

RUN apk update && apk upgrade && \
    apk -v --virtual build-deps add --update go>1.6 curl git gcc musl-dev && \
    export GOPATH=/go && \
    go get -v github.com/influxdata/kapacitor && \
    cd $GOPATH/src/github.com/influxdata/kapacitor && \
    git checkout -q --detach "v${KAPACITOR_VERSION}" && \
    go get -v ./... && \
    go build -v ./cmd/kapacitor && \
    go build -v ./cmd/kapacitord && \
    mv $GOPATH/bin/* /bin/ && \
    mkdir -p /var/lib/kapacitor && \
    apk del build-deps && cd / && rm -rf /var/cache/apk/* $GOPATH

EXPOSE 9092

VOLUME /var/lib/kapacitor

ENV INFLUXDB_URL http://localhost:8086
ENV INFLUXDB_DB telegraf
ENV INFLUXDB_RP default

ADD run.sh /run.sh
ADD kapacitor.conf /etc/kapacitor/kapacitor.conf.tpl
ADD e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl /.kapacitor/replay/e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/run.sh"]

LABEL axway_image=kapacitor
# will be updated whenever there's a new commit
LABEL commit=${GIT_COMMIT}
LABEL branch=${GIT_BRANCH}
