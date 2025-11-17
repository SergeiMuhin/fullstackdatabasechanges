#!/bin/sh

echo "Waiting for TiCDC to be ready..."
sleep 15

echo "Creating CDC changefeed to Kafka..."
curl -X POST http://ticdc:8300/api/v2/changefeeds \
  -H "Content-Type: application/json" \
  -d '{
    "changefeed_id": "kafka-changefeed",
    "sink_uri": "kafka://kafka:29092/tidb-cdc-events?protocol=canal-json&kafka-version=2.6.0",
    "config": {
      "filter": {
        "rules": ["testdb.*"]
      }
    }
  }'

echo "CDC changefeed created!"