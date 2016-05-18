FROM alpine:3.3
MAINTAINER Nicolas Degory <ndegory@axway.com>

RUN apk update && \
    apk --no-cache add python ca-certificates && \
    apk --virtual envtpl-deps add --update py-pip python-dev curl && \
    curl https://bootstrap.pypa.io/ez_setup.py | python && \
    pip install envtpl && \
    apk del envtpl-deps && rm -rf /var/cache/apk/*

ENV KAPACITOR_VERSION 0.13.1

RUN echo "http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk upgrade && \
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


RUN apk --no-cache add curl bash

# Add ContainerPilot
ENV CONTAINERPILOT 2.1.0
RUN curl -Lo /tmp/cb.tar.gz https://github.com/joyent/containerpilot/releases/download/$CONTAINERPILOT/containerpilot-$CONTAINERPILOT.tar.gz \
&& tar -xz -f /tmp/cb.tar.gz \
&& mv ./containerpilot /bin/
COPY containerpilot.json /etc/containerpilot.json
COPY start.sh /start.sh
COPY stop.sh /stop.sh
RUN chmod +x /*.sh

#ENV CONSUL=consul:8500
ENV CP_LOG_LEVEL=ERROR
ENV CONTAINERPILOT=file:///etc/containerpilot.json
ENV DEPENDENCIES=influxdb

COPY run.sh /run.sh
COPY kapacitor.conf /etc/kapacitor.conf.tpl
COPY e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl /.kapacitor/replay/e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl

CMD ["/start.sh"]

LABEL axway_image=kapacitor
# will be updated whenever there's a new commit
LABEL commit=${GIT_COMMIT}
LABEL branch=${GIT_BRANCH}
