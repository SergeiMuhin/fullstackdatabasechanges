# TiDB Change Data Capture Monitoring System

A complete distributed system for real-time database change monitoring using TiDB, Kafka, and observability stack.

---

## 🏗️ Architecture

This system captures every database change in real-time and provides comprehensive monitoring through multiple layers:
```
┌─────────────────────────────────────────────────────────────┐
│                     TiDB Distributed Database                │
│  ┌────────┐    ┌────────┐    ┌────────┐                    │
│  │   PD   │───▶│  TiKV  │◀───│  TiDB  │                    │
│  └────────┘    └────────┘    └───┬────┘                    │
└────────────────────────────────────┼──────────────────────────┘
                                     │
                            ┌────────▼────────┐
                            │     TiCDC       │
                            └────────┬────────┘
                                     │
                            ┌────────▼────────┐
                            │   Apache Kafka  │
                            └────────┬────────┘
                                     │
                       ┌─────────────▼─────────────┐
                       │   Node.js Consumer        │
                       │  ┌─────────┬─────────┐   │
                       │  │ Logging │ Metrics │   │
                       └──┴─────────┴─────────┴───┘
                          │                   │
                ┌─────────▼──────┐   ┌───────▼────────┐
                │ Elasticsearch  │   │   Prometheus   │
                └────────┬───────┘   └────────┬───────┘
                         │                     │
                         └──────────┬──────────┘
                                    │
                            ┌───────▼────────┐
                            │    Grafana     │
                            └────────────────┘
```

---

## 🎯 Key Components

**Database Layer:**
- PD (Placement Driver) - Cluster metadata and coordination
- TiKV - Distributed transactional key-value storage
- TiDB - MySQL-compatible SQL layer
- TiCDC - Captures database changes in real-time

**Streaming Layer:**
- Apache Kafka - Message broker for CDC events
- Zookeeper - Kafka coordination service

**Processing Layer:**
- Node.js Consumer - Consumes CDC events from Kafka, logs to Elasticsearch, exposes Prometheus metrics

**Observability Layer:**
- Elasticsearch - Stores full CDC event history
- Filebeat - Ships TiCDC system logs
- Prometheus - Time-series metrics database
- Grafana - Unified dashboard for visualization

---

## 🚀 Quick Start

**Prerequisites:**
- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM minimum
- 20GB disk space

**Start the system:**
```bash
docker-compose up
```

> **Note:** First startup takes 2-3 minutes while TiDB cluster initializes.

**Access Services:**

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana Dashboard | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| Elasticsearch | http://localhost:9200 | - |
| TiDB (MySQL) | localhost:4000 | root / (no password) |
| Kafka | localhost:9092 | - |

---

## 📊 Grafana Dashboard

The system auto-provisions a dashboard with:

1. **CDC Events Table** (from Elasticsearch)
   - Real-time list of all database changes
   - Filterable by table, operation type, timestamp
   - Full event data including old/new values

2. **Operations Pie Charts** (from Prometheus)
   - Total Count - Cumulative operations since startup
   - Last 1 Hour - Operations in the past hour
   - INSERT / UPDATE / DELETE distribution

---

## 🧪 Testing the System

### Option 1: Automated Test Data

Run the test data generator:
```bash
./scripts/generate-test-data.sh
```

This creates 20 INSERTs, 10 UPDATEs, and 5 DELETEs.

### Option 2: Manual Testing

Connect to TiDB:
```bash
mysql -h 127.0.0.1 -P 4000 -u root testdb
```

Run some queries:
```sql
-- Insert
INSERT INTO users (username, email, password) 
VALUES ('john_doe', 'john@example.com', SHA2('password123', 256));

-- Update
UPDATE users SET email = 'john.doe@example.com' WHERE username = 'john_doe';

-- Delete
DELETE FROM users WHERE username = 'john_doe';
```

Watch the changes appear in Grafana in real-time!

---

## 📁 Project Structure
```
.
├── docker-compose.yml           # Main orchestration
├── .gitignore                   # Git ignore rules
├── README.md                    # This file
├── filebeat.yml                 # Filebeat config
│
├── sql/
│   ├── schema.sql              # Database schema
│   └── seed.sql                # Initial data
│
├── scripts/
│   ├── init.sh                 # DB initialization
│   ├── setup-cdc.sh            # CDC changefeed setup
│   ├── create-kafka-topics.sh  # Kafka topic creation
│   ├── wait-for-datasources.sh # Grafana health check
│   └── generate-test-data.sh   # Test data generator
│
├── consumer/
│   ├── Dockerfile
│   ├── package.json
│   └── index.js                # Kafka consumer
│
├── prometheus/
│   └── prometheus.yml          # Prometheus config
│
└── grafana/provisioning/
    ├── datasources/
    │   └── datasources.yml     # Auto-configured datasources
    └── dashboards/
        ├── dashboard.yml
        └── cdc-dashboard.json  # Pre-built dashboard
```

---

## 🗄️ Database Schema

**users table:**
- id (PK, AUTO_INCREMENT)
- username (UNIQUE)
- email
- password (SHA256 hashed)
- created_at, updated_at

**orders table:**
- id (PK, AUTO_INCREMENT)
- user_id (FK → users)
- product_name
- amount (DECIMAL)
- status
- created_at, updated_at

**products table:**
- id (PK, AUTO_INCREMENT)
- name
- price (DECIMAL)
- stock (INT)
- created_at, updated_at

**Default User:**
- Username: `admin`
- Email: `admin@example.com`
- Password: `admin123` (hashed in database)

---

## 🔍 Monitoring & Metrics

**Prometheus Metrics Endpoint:**
```bash
curl http://localhost:9091/metrics
```

Example output:
```
tidb_cdc_operations_total{tablename="users", op="insert"} 42
tidb_cdc_operations_total{tablename="users", op="update"} 18
tidb_cdc_operations_total{tablename="users", op="delete"} 7
```

**Elasticsearch CDC Events:**
```bash
curl http://localhost:9200/tidb-cdc-events/_search?pretty
```

**View Logs:**
```bash
docker logs cdc-consumer
docker logs ticdc
docker logs tidb-server
```

---

## 🐛 Troubleshooting

### TiDB Takes Long to Start

**Expected behavior.** TiKV initialization takes 1-3 minutes on first startup.

Check progress:
```bash
docker logs tidb-server -f
```

### CDC Not Capturing Events

Check TiCDC status:
```bash
docker logs ticdc
```

Verify changefeed exists:
```bash
curl http://localhost:8300/api/v2/changefeeds
```

Should return:
```json
{
  "kafka-changefeed": {
    "state": "normal",
    "checkpoint_tso": ...
  }
}
```

### Grafana Dashboard Shows No Data

**Check Elasticsearch:**
```bash
curl http://localhost:9200/tidb-cdc-events/_count
```

**Check Prometheus:**
```bash
curl http://localhost:9091/metrics | grep tidb_cdc
```

**Check Grafana datasources:**
1. Go to Connections → Data sources
2. Confirm both Elasticsearch and Prometheus show green status

### Consumer Not Starting

View logs:
```bash
docker logs cdc-consumer -f
```

Common issues:
- Kafka not ready - Wait 30 seconds and restart
- Elasticsearch unavailable - Check `docker logs elasticsearch`

---

## 🧹 Cleanup

**Stop containers (keep data):**
```bash
docker-compose down
```

**Remove everything (including volumes):**
```bash
docker-compose down -v
```

**Remove specific volume:**
```bash
docker volume rm <project-name>_tikv-data
```

---

## 🏗️ Architecture Decisions

**Why TiDB?**
- Horizontally scalable SQL database
- Built-in CDC capabilities (TiCDC)
- MySQL-compatible

**Why Kafka?**
- Reliable message buffering
- Decouples CDC source from consumers
- Enables multiple consumers

**Why Separate Consumer?**
- Separation of concerns
- Flexibility to add more consumers
- Resilience - consumer crashes don't affect CDC

**Why Elasticsearch + Prometheus?**
- Elasticsearch - Full event history with search
- Prometheus - Time-series metrics for aggregations
- Different use cases - logs vs. metrics

**Init Container Pattern:**
- db-init - Database schema/seed setup
- cdc-setup - TiCDC changefeed configuration
- kafka-init - Topic creation
- grafana-init - Datasource health checks
- Benefits: Idempotent, clear separation, production-ready

---

## 📝 Important Notes

- Prometheus `increase()` function may show decimal values due to linear interpolation
- First-time startup: Allow 2-3 minutes for TiDB initialization
- All data persists in Docker volumes
- Grafana dashboards auto-load on startup (10-15 seconds)

---

## 🎓 Resources

- [TiDB Documentation](https://docs.pingcap.com/tidb/stable)
- [TiCDC Overview](https://docs.pingcap.com/tidb/stable/ticdc-overview)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)

---

## 📄 License

This project is for educational/assessment purposes.

---

**Built with:** TiDB • Kafka • Node.js • Elasticsearch • Prometheus • Grafana