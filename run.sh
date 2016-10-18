#!/bin/bash

KAPACITORD_BIN=/bin/kapacitord
KAPACITOR_BIN=/bin/kapacitor
KAPACITOR_CONF=/etc/kapacitor/kapacitor.conf
CONFIG_OVERRIDE_FILE="/etc/base-config/kapacitor/kapacitor.conf"
CONFIG_EXTRA_DIR="/etc/extra-config/kapacitor/"

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
    KAPACITOR_HOSTNAME=$(ip a show dev eth0 | grep inet | grep eth0 | tail -1 | sed -e 's/^.*inet.//g' -e 's/\/.*$//g')
  fi
fi

if [[ -n "$CONFIG_ARCHIVE_URL" ]]; then
  echo "INFO - Download configuration archive file $CONFIG_ARCHIVE_URL..."
  curl -L "$CONFIG_ARCHIVE_URL" -o /tmp/config.tgz
  if [[ $? -eq 0 ]]; then
    tmpd=$(mktemp -d)
    gunzip -c /tmp/config.tgz | tar xf - -C $tmpd
    echo "INFO - Overriding configuration file:"
    find $tmpd/*/base-config/kapacitor 2>/dev/null
    echo "INFO - Extra configuration file:"
    find $tmpd/*/extra-config/kapacitor 2>/dev/null
    mv $tmpd/*/extra-config $tmpd/*/base-config /etc/ 2>/dev/null
    rm -rf /tmp/config.tgz "$tmpd"
  else
    echo "WARN - download failed, ignore"
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
    echo "$f" | grep '*' && break
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
echo "SLACK: ${OUTPUT_SLACK_ENABLED:-false} (${OUTPUT_SLACK_CHANNEL:-#kapacitor})"
echo
if [[ "x$OUTPUT_SLACK_ENABLED" = "xtrue" ]]; then
  curl -s -X POST -H 'Content-type: application/json' --data '{"channel": "'${OUTPUT_SLACK_CHANNEL}'", "text": "Kapacitor starts on '${KAPACITOR_HOSTNAME:-unknown host}' ('$(hostname)')"}' "$OUTPUT_SLACK_WEBHOOK_URL"
fi
CMD="$KAPACITORD_BIN"
CMDARGS="-config $KAPACITOR_CONF $@"
exec "$CMD" $CMDARGS
