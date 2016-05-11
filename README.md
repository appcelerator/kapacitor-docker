# docker-kapacitor


Docker Image for [InfluxData Kapacitor](https://influxdata.com/time-series-platform/kapacitor/).

## Run

```
docker run -t appcelerator/kapacitor
```

## Kapacitor

Kapacitor is setup to load a default CPU_ALERT and send the alerts to slack on a channel named **"kapacitor-test"**

A stream recording was included with the image and can be used to simulate a heavy CPU load that will trigger the alerts.

     docker exec -it $(docker ps --format "{{.ID}}" --filter "name=kapacitor") kapacitor replay -id e494ce6c-d063-46f8-9d71-9030a29eef4b -name cpu_alert -fast
