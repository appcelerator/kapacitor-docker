# docker-kapacitor


Docker Image for [InfluxData Kapacitor](https://influxdata.com/time-series-platform/kapacitor/).

## Run

    docker run appcelerator/kapacitor

## Configuration (ENV, -e)

Variable | Description | Default value | Sample value 
-------- | ----------- | ------------- | ------------
KAPACITOR_LOG_LEVEL | sets the log level | INFO |
KAPACITOR_HOSTNAME | sets the hostname. If value is _auto_, the ip will be guessed | localhost | auto
CONFIG_ARCHIVE_URL | URL of static configuration file tarball archive | |
INFLUXDB_URL | URL of influxdb | http://localhost:8086 | http://influxdb:8086
INFLUXDB_DB | INFLUXDB database, used for alert definition | telegraf |
INFLUXDB_RP | INFLUXDB retention policy, used for alert definition | default |
SUBSCRIPTION_PROTOCOL | Which protocol to use for subscriptions | http | udp, http or https
SUBSCRIPTION_SYNC_INTERVAL | Subscription resync time interval | 1m0s |
STARTUP_TIMEOUT | Maximum time to try and connect to InfluxDB during startup | 5m |
DISABLE_SUBSCRIPTIONS | Turn off all subscriptions | false |
INTERNAL_STATS | Emit internal statistics about Kapacitor | false |
OUTPUT_SMTP_ENABLED | SMTP output | false |
OUTPUT_SMTP_HOST | SMTP host | |
OUTPUT_SMTP_PORT | SMTP port | |
OUTPUT_SMTP_FROM | Sender | |
OUTPUT_SMTP_TO | Recipient | |
OUTPUT_SLACK_ENABLED | Slack output | false |
OUTPUT_SLACK_WEBHOOK_URL | Slack webhook URL | |
OUTPUT_SLACK_CHANNEL | Slack Channel, with the pound sign | #kapacitor | @johnsnow
OUTPUT_SLACK_STATE_CHANGE_ONLY | only report state changes | | false
OUTPUT_SLACK_GLOBAL | sends all alerts to slack | | false
OUTPUT_SLACK_USERNAME | sender name | kapacitor | 
CONFIG_ARCHIVE_URL | URL of a configuration archive | | 

## Kapacitor

Use the CONFIG_ARCHIVE_URL or alternatively use a local volume mapping to a file in /etc/extra-config/kapacitor/ if you want a configuration to be loaded the first time the container starts.

Kapacitor will look for /etc/extra-config/kapacitor/*.tick files and configure the alerts accordingly. A file named cpu.tick or cpu_alert.tick will result in an alarm named cpu_alert.

    docker run -v /var/lib/kapacitor/alerts:/etc/extra-config/kapacitor/kapacitor.alerts:ro appcelerator/kapacitor

A stream recording was included with the image and can be used to simulate a heavy CPU load that will trigger the alerts.

    docker exec -it $(docker ps --format "{{.ID}}" --filter "name=kapacitor") kapacitor replay -recording e494ce6c-d063-46f8-9d71-9030a29eef4b -task cpu_alert

## Tags

- kapacitor-0.13
- kapacitor-1.0.2-2, kapacitor-1.0
- kapacitor-1.1.1, kapacitor-1.1
- kapacitor-1.2.0, kapacitor-1.2, latest
