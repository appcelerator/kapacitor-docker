#!/bin/sh

KAPACITORD_BIN=/bin/kapacitord
KAPACITOR_BIN=/bin/kapacitor
KAPACITOR_CONF=/etc/kapacitor.conf

echo "$INFLUXDB_URL" | egrep -q "^https?://"
if [ $? -ne 0 ]; then
  echo "WARNING: missing protocol in INFLUXDB_URL, adding http://"
  INFLUXDB_URL="http://$INFLUXDB_URL"
fi
if [ -f "$KAPACITOR_CONF.tpl" ]; then
  # deadman configuration can contain markups similar to those of envtpl
  cat "$KAPACITOR_CONF.tpl" | sed '/{{ \./ s/{{\([^{]*\)}}/@@\1@@/g' > "$KAPACITOR_CONF.escaped.tpl"
  envtpl $KAPACITOR_CONF.escaped.tpl
  cat "$KAPACITOR_CONF.escaped" | sed '/@@ \./ s/@@\([^@]*\)@@/{{\1}}/g' > "$KAPACITOR_CONF"
fi
if [ ! -f "$KAPACITOR_CONF" ]; then
  echo "No $KAPACITOR_CONF, abort"
fi

KAPACITOR_HOSTNAME="${KAPACITOR_HOSTNAME:-$HOSTNAME}"
KAPACITOR_HOST="127.0.0.1"
KAPACITOR_API_PORT="9092"
API_URL="http://${KAPACITOR_HOST}:${KAPACITOR_API_PORT}"
wait_for_start_of_kapacitor(){
    #wait for the startup of kapacitor
    local retry=0
    echo "waiting for availability of kapacitor..."
    #while ! curl ${API_URL} 2>/dev/null; do
    while ! $KAPACITOR_BIN -url $API_URL list tasks; do
        netstat -na | grep -w 9092
        retry=$((retry+1))
        if [ $retry -gt 15 ]; then
            echo
            echo "ERROR: unable to reach kapacitor"
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    echo "Kapacitor is available"
}

echo "Kapacitor in background for alert configuration"
cat "$KAPACITOR_CONF" | sed 's/ enabled = true/ enabled = false/' > "$KAPACITOR_CONF.start"
"$KAPACITORD_BIN" -hostname "$KAPACITOR_HOST" -config "$KAPACITOR_CONF.start" &
wait_for_start_of_kapacitor

for alert in $(ls /etc/*.tick 2>/dev/null); do
  alertname="$(basename $alert .tick | sed 's/_alert//')"
  echo "defining alert $alertname..."
  $KAPACITOR_BIN define ${alertname}_alert -type stream  -tick $alert  -dbrp ${INFLUXDB_DB:-telegraf}.${INFLUXDB_RP:-default}
  $KAPACITOR_BIN enable ${alertname}_alert
  $KAPACITOR_BIN show ${alertname}_alert
done

echo
echo "Restarting Kapacitor..."
killall "$(basename $KAPACITORD_BIN)"
echo
echo "Enabled outputs:"
echo "SMTP: ${OUTPUT_SMTP_ENABLED:-false} (${OUTPUT_SMTP_TO:-default})"
echo "SLACK: ${OUTPUT_SLACK_ENABLED:-false} (#${OUTPUT_SLACK_CHANNEL:-kapacitor})"
echo
"$KAPACITORD_BIN" -config /etc/kapacitor.conf
