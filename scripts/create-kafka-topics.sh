#!/bin/sh

echo "Waiting for Kafka to be ready..."
until kafka-topics --bootstrap-server kafka:29092 --list &>/dev/null; do
  echo "Kafka not ready, retrying in 3s..."
  sleep 3
done

echo "Creating Kafka topic: tidb-cdc-events"
kafka-topics --bootstrap-server kafka:29092 \
  --create \
  --if-not-exists \
  --topic tidb-cdc-events \
  --partitions 3 \
  --replication-factor 1

echo "Kafka topic created!"