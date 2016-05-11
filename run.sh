#!/bin/sh

set -m

KAPACITOR_HOST="localhost"
KAPACITOR_API_PORT="9092"
API_URL="http://${KAPACITOR_HOST}:${KAPACITOR_API_PORT}"

wait_for_start_of_influxdb(){
    #wait for the startup of influxdb
    local retry=0
    while ! curl ${API_URL}/ping 2>/dev/null; do
        retry=$((retry+1))
        if [ $retry -gt 15 ]; then
            echo "\nERROR: unable to reach kapacitor"
            exit 1
        fi
        echo -n "."
        sleep 3
    done
    echo "Kapacitor is available"
}
sed -i 's@INFLUXDB_URLS@'$INFLUXDB_URLS'@' /kapacitor.conf
echo "Kapacitor in background"
exec kapacitord -hostname $HOSTNAME -config kapacitor.conf &
wait_for_start_of_influxdb
#Setup The Alert
todo_(){
#Can't get the job control stuff to work properly
  kapacitor define -name cpu_alert  -type stream  -tick cpu_alert.tick  -dbrp telegraf.default
  kapacitor enable cpu_alert
  kapacitor show cpu_alert
#  echo "=> Stopping Kapacitor ..."
#  if ! kill -s TERM %1 || ! wait %1; then
#    echo >&2 'Kapacitor init process failed.'
#    exit 1
#  fi
}
todo_
fg
