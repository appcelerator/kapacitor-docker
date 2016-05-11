FROM tutum/curl:trusty
MAINTAINER Chris Coy <ccoy@axway.com>

ENV KAPACITOR_VERSION 0.12.0-1 


RUN curl -s -o /tmp/kapacitor_latest_amd64.deb https://s3.amazonaws.com/kapacitor/kapacitor_${KAPACITOR_VERSION}_amd64.deb && \
    dpkg -i /tmp/kapacitor_latest_amd64.deb && \
    rm /tmp/kapacitor_latest_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 9092

VOLUME /var/lib/kapacitor

COPY run.sh /run.sh
COPY kapacitor.conf /kapacitor.conf
COPY cpu_alert.tick /cpu_alert.tick
COPY e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl /.kapacitor/replay/e494ce6c-d063-46f8-9d71-9030a29eef4b.srpl
ENTRYPOINT ["/run.sh"]
