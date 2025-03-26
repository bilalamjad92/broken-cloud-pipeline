#!/bin/bash
ALB_DNS="$1"
for i in {1..5}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${ALB_DNS}")
  echo "Health check $i: $STATUS"
  sleep 1
done
