#!/bin/bash
TESTID="test-$(openssl rand -base64 12)"
echo "TESTID: $TESTID"

export K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write
k6 run -o experimental-prometheus-rw script.js -u 10 -d 20m --tag testid=$TESTID $@