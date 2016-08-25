#!/bin/bash

KAPACITOR_HOST=${KAPACITOR_HOST:-kapacitor}

# wait for init of kapacitor, to avoid testing the pre config start
sleep 5
echo -n "test 1... "
i=0
r=1
while [[ $r -ne 0 ]]; do
  ((i++))
  sleep 1
  curl -I $KAPACITOR_HOST:9092/kapacitor/v1/ping 2>/dev/null | grep -q "HTTP/1.1 204 No Content"
  r=$?
  if [[ $i -gt 25 ]]; then break; fi
  echo -n "+"
done
if [[ $r -ne 0 ]]; then
  echo
  echo "ping failed"
  curl -I $KAPACITOR_HOST:9092/kapacitor/v1/ping
  echo "Running containers:"
  docker ps
  ci=$(docker ps -a | grep /influxdb | head -1 | awk '{print $1}')
  echo "logs from influxdb $ci:"
  docker logs $ci
  ck=$(docker ps -a | grep /kapacitor | head -1 | awk '{print $1}')
  echo "logs from kapacitor $ck:"
  docker logs $ck
  exit 1
fi
echo "[OK]"

echo -n "test 2... "
r=$(curl $KAPACITOR_HOST:9092/kapacitor/v1/tasks 2>/dev/null | jq -r '.tasks | length')
if [[ $? -ne 0 || $r -lt 2 ]]; then
  echo
  echo "task list failed ($r)"
  curl $KAPACITOR_HOST:9092/kapacitor/v1/tasks
  exit 1
fi
echo "[OK]"

echo "all tests passed successfully"
