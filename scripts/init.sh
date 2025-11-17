#!/bin/bash

echo "Waiting for TiDB to be ready..."
until mysql -h tidb -P 4000 -u root -e "SELECT 1" &>/dev/null; do
  echo "TiDB not ready yet, retrying in 3 seconds..."
  sleep 3
done

echo "TiDB is ready! Running schema..."
mysql -h tidb -P 4000 -u root < /docker-entrypoint-initdb.d/schema.sql

echo "Running seed data..."
mysql -h tidb -P 4000 -u root < /docker-entrypoint-initdb.d/seed.sql

echo "Database initialization complete!"