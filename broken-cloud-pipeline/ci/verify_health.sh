#!/bin/bash
ALB_DNS="$1"

# Validate ALB_DNS
if [ -z "$ALB_DNS" ]; then
  echo "Error: ALB_DNS not provided!"
  exit 1
fi

# Use HTTP (matches ALB listener) and /health path
HEALTH_URL="http://${ALB_DNS}:80/health"

for i in {1..5}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")
  echo "Health check $i: $STATUS"
  # FLAW: Redundant calls (5x) instead of one, wasting resources
  if [ "$STATUS" -ne 200 ]; then
    echo "Health check failed: Expected 200, got $STATUS"
    exit 1
  fi
  sleep 1
done

echo "Deployment verified successfully!"
