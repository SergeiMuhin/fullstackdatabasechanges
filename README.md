# TiDB CDC Monitoring System

Complete ecosystem for monitoring TiDB database changes with Kafka, Elasticsearch, Prometheus, and Grafana.

## Architecture

- **TiDB**: Distributed SQL database
- **TiCDC**: Change Data Capture component
- **Kafka**: Message broker for CDC events
- **Node.js Consumer**: Processes CDC events, logs to Elasticsearch, exposes Prometheus metrics
- **Elasticsearch**: Stores CDC event logs
- **Filebeat**: Ships TiCDC logs to Elasticsearch
- **Prometheus**: Collects metrics from consumer
- **Grafana**: Visualizes data with dashboards

## Prerequisites

- Docker
- Docker Compose

## Quick Start
```bash
docker-compose up
```

That's it! The entire stack will start automatically.

## Access Points

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Elasticsearch**: http://localhost:9200
- **TiDB**: localhost:4000 (MySQL protocol)
- **Kafka**: localhost:9092

## Default User
```
Username: admin
Email: admin@example.com
Password: admin123 (hashed in DB)
```

## Testing CDC

Connect to TiDB and make some changes:
```bash
mysql -h 127.0.0.1 -P 4000 -u root testdb

# Insert
INSERT INTO users (username, email, password) VALUES ('test', 'test@example.com', 'password');

# Update
UPDATE users SET email = 'newemail@example.com' WHERE username = 'test';

# Delete
DELETE FROM users WHERE username = 'test';
```

Watch the events flow through Kafka → Consumer → Elasticsearch/Prometheus → Grafana!

## Project Structure
```
.
├── docker-compose.yml          # Main orchestration
├── sql/
│   ├── schema.sql             # Database schema
│   └── seed.sql               # Initial data
├── scripts/
│   ├── init.sh                # DB initialization
│   └── setup-cdc.sh           # CDC changefeed setup
├── consumer/
│   ├── Dockerfile
│   ├── package.json
│   └── index.js               # Kafka consumer
├── prometheus/
│   └── prometheus.yml         # Prometheus config
├── grafana/provisioning/
│   ├── datasources/
│   │   └── datasources.yml    # Auto-configured datasources
│   └── dashboards/
│       ├── dashboard.yml
│       └── cdc-dashboard.json # Pre-built dashboard
└── filebeat.yml               # Filebeat config
```

## Troubleshooting

### TiDB won't start
Wait 30-60 seconds for TiKV to initialize.

### CDC not capturing events
Check TiCDC logs: `docker logs ticdc`
Verify changefeed: `curl http://localhost:8300/api/v2/changefeeds`

### No data in Grafana
- Verify Elasticsearch has data: `curl http://localhost:9200/tidb-cdc-events/_search`
- Check Prometheus metrics: `curl http://localhost:9091/metrics`

## Clean Up
```bash
docker-compose down -v
```

This removes all containers and volumes.
```

---

**DONE! 🚀**

Create these files in your project folder with this structure:
```
project/
├── docker-compose.yml
├── filebeat.yml
├── README.md
├── sql/
│   ├── schema.sql
│   └── seed.sql
├── scripts/
│   ├── init.sh
│   └── setup-cdc.sh
├── consumer/
│   ├── Dockerfile
│   ├── package.json
│   └── index.js
├── prometheus/
│   └── prometheus.yml
└── grafana/provisioning/
    ├── datasources/
    │   └── datasources.yml
    └── dashboards/
        ├── dashboard.yml
        └── cdc-dashboard.json