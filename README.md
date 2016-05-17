# docker-kapacitor


Docker Image for [InfluxData Kapacitor](https://influxdata.com/time-series-platform/kapacitor/).

## Run

```
docker run appcelerator/kapacitor
```

## Environment variables

- KAPACITOR_LOG_LEVEL - sets the log level, defaults to INFO
- KAPACITOR_HOSTNAME - sets the hostname, defaults to the container hostname
- INFLUXDB_URL - URL of influxdb, defaults to http://localhost:8086
- INFLUXDB_DB - INFLUXDB database, used for alert definition, defaults to telegraf
- INFLUXDB_RP - INFLUXDB retention policy, used for alert definition, defaults to default
- OUTPUT_SMTP_ENABLED - defaults to false
- OUTPUT_SMTP_HOST - SMTP host
- OUTPUT_SMTP_PORT - SMTP port
- OUTPUT_SMTP_FROM - Sender
- OUTPUT_SMTP_TO - Recipient
- OUTPUT_SLACK_ENABLED - defaults to false
- OUTPUT_SLACK_WEBHOOK_URL - Slack webhook URL
- OUTPUT_SLACK_CHANNEL - Channel, without the pound sign, defaults to kapacitor
- OUTPUT_SLACK_STATE_CHANGE_ONLY - only report state changes
- OUTPUT_SLACK_GLOBAL - sends all alerts to slack
- CONSUL - Consul URL for container pilot, example: consul:8500, disabled by default

## Kapacitor

Kapacitor will look for /etc/*.tick files and configure the alerts accordingly. A file named cpu.tick or cpu_alert.tick will result in an alarm named cpu_alert.

A stream recording was included with the image and can be used to simulate a heavy CPU load that will trigger the alerts.

     docker exec -it $(docker ps --format "{{.ID}}" --filter "name=kapacitor") kapacitor replay -id e494ce6c-d063-46f8-9d71-9030a29eef4b -name cpu_alert -fast
