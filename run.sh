#!/bin/bash

KAPACITORD_BIN=/bin/kapacitord
KAPACITOR_BIN=/bin/kapacitor
KAPACITOR_CONF=/etc/kapacitor/kapacitor.conf
CONFIG_OVERRIDE_FILE="/etc/base-config/kapacitor/kapacitor.conf"
CONFIG_EXTRA_DIR="/etc/extra-config/kapacitor/"
PILOT="/bin/amp-pilot"

echo "$INFLUXDB_URL" | egrep -q "^https?://"
if [ $? -ne 0 ]; then
  echo "WARNING: missing protocol in INFLUXDB_URL, adding http://"
  INFLUXDB_URL="http://$INFLUXDB_URL"
fi
if [ "x$KAPACITOR_HOSTNAME" = "xauto" ]; then
  # try AWS
  KAPACITOR_HOSTNAME=$(timeout -t 2 curl http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null)
  if [ -z "$KAPACITOR_HOSTNAME" ]; then
    # get local IP
    KAPACITOR_HOSTNAME=$(ip a show dev eth0 | grep inet | grep eth0 | sed -e 's/^.*inet.//g' -e 's/\/.*$//g')
  fi
fi

if [ -f "$CONFIG_OVERRIDE_FILE" ]; then
  echo "Override Kapacitor configuration file"
  cp "${CONFIG_OVERRIDE_FILE}" "${KAPACITOR_CONF}"
else
  if [ -f "$KAPACITOR_CONF.tpl" ]; then
    # deadman configuration can contain markups similar to those of envtpl
    cat "$KAPACITOR_CONF.tpl" | sed '/{{ \./ s/{{\([^{]*\)}}/@@\1@@/g' > "$KAPACITOR_CONF.escaped.tpl"
    envtpl $KAPACITOR_CONF.escaped.tpl
    cat "$KAPACITOR_CONF.escaped" | sed '/@@ \./ s/@@\([^@]*\)@@/{{\1}}/g' > "$KAPACITOR_CONF"
  fi
fi
if [ ! -f "$KAPACITOR_CONF" ]; then
  echo "No $KAPACITOR_CONF, abort"
fi

KAPACITOR_HOST="127.0.0.1"
KAPACITOR_API_PORT="9092"
API_URL="http://${KAPACITOR_HOST}:${KAPACITOR_API_PORT}"

wait_for_start_of_kapacitor(){
    #wait for the startup of kapacitor
    local retry=0
    echo "waiting for availability of kapacitor..."
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

ls $CONFIG_EXTRA_DIR/*.tick >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Kapacitor in background for alert configuration"
  cat "$KAPACITOR_CONF" | sed 's/ enabled = true/ enabled = false/' > "$KAPACITOR_CONF.start"
  "$KAPACITORD_BIN" -config "$KAPACITOR_CONF.start" &
  wait_for_start_of_kapacitor

  for alert in $CONFIG_EXTRA_DIR/*.tick; do
    alertname="$(basename $alert .tick | sed 's/_alert//')"
    echo "defining alert $alertname..."
    $KAPACITOR_BIN define ${alertname}_alert -type stream  -tick $alert  -dbrp ${INFLUXDB_DB:-telegraf}.${INFLUXDB_RP:-default}
    $KAPACITOR_BIN enable ${alertname}_alert
    $KAPACITOR_BIN show ${alertname}_alert
  done

  echo
  echo "Restarting Kapacitor..."
  killall "$(basename $KAPACITORD_BIN)"
else
  echo "no alert configuration found"
fi
echo
echo "Enabled outputs:"
echo "SMTP: ${OUTPUT_SMTP_ENABLED:-false} (${OUTPUT_SMTP_TO:-default})"
echo "SLACK: ${OUTPUT_SLACK_ENABLED:-false} (#${OUTPUT_SLACK_CHANNEL:-kapacitor})"
echo
CMD="$KAPACITORD_BIN"
CMDARGS="-config $KAPACITOR_CONF"
export AMP_LAUNCH_CMD="$CMD $CMDARGS"
if [[ -n "$CONSUL" && -n "$PILOT" ]]; then
    echo "registering in Consul with $PILOT"
    exec "$PILOT" "$CMD" $CMDARGS
else
    echo "not registering in Consul"
    exec "$CMD" $CMDARGS
fi
