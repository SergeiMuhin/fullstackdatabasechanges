const { Kafka } = require('kafkajs');
const { Client } = require('@elastic/elasticsearch');
const client = require('prom-client');
const http = require('http');

// Prometheus setup
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// CDC operations counter
const cdcCounter = new client.Counter({
  name: 'tidb_cdc_operations_total',
  help: 'Total number of CDC operations by table and operation type',
  labelNames: ['tablename', 'op'],
  registers: [register]
});

// Elasticsearch client
const esClient = new Client({
  node: process.env.ELASTICSEARCH_URL || 'http://elasticsearch:9200'
});

// Kafka setup
const kafka = new Kafka({
  clientId: 'cdc-consumer',
  brokers: [process.env.KAFKA_BROKER || 'kafka:29092']
});

const consumer = kafka.consumer({ groupId: 'cdc-consumer-group' });

// Create Elasticsearch index
async function setupElasticsearch() {
  try {
    const indexExists = await esClient.indices.exists({ index: 'tidb-cdc-events' });
    if (!indexExists) {
      await esClient.indices.create({
        index: 'tidb-cdc-events',
        body: {
          mappings: {
            properties: {
              timestamp: { type: 'date' },
              table: { type: 'keyword' },
              operation: { type: 'keyword' },
              data: { type: 'object' },
              old_data: { type: 'object' }
            }
          }
        }
      });
      console.log('Elasticsearch index created');
    }
  } catch (error) {
    console.error('Error setting up Elasticsearch:', error);
  }
}

// Process CDC message
async function processCDCMessage(message) {
  try {
    const payload = JSON.parse(message.value.toString());
    
    // Canal-JSON format parsing
    if (payload.data && Array.isArray(payload.data)) {
      for (const row of payload.data) {
        const tableName = payload.table || 'unknown';
        const operation = payload.type || 'unknown'; // INSERT, UPDATE, DELETE
        
        // Increment Prometheus counter
        cdcCounter.inc({ tablename: tableName, op: operation.toLowerCase() });
        
        // Log to Elasticsearch
        await esClient.index({
          index: 'tidb-cdc-events',
          body: {
            timestamp: new Date(),
            table: tableName,
            operation: operation,
            database: payload.database,
            data: row,
            old_data: payload.old ? payload.old[0] : null
          }
        });
        
        console.log(`Processed: ${operation} on ${tableName}`);
      }
    }
  } catch (error) {
    console.error('Error processing message:', error);
  }
}

// Start consumer
async function run() {
  await setupElasticsearch();
  
  await consumer.connect();
  await consumer.subscribe({ topic: process.env.KAFKA_TOPIC || 'tidb-cdc-events', fromBeginning: true });
  
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      await processCDCMessage(message);
    },
  });
  
  console.log('CDC Consumer started and listening...');
}

// Prometheus metrics endpoint
const server = http.createServer(async (req, res) => {
  if (req.url === '/metrics') {
    res.setHeader('Content-Type', register.contentType);
    res.end(await register.metrics());
  } else {
    res.statusCode = 404;
    res.end('Not Found');
  }
});

const port = process.env.PROMETHEUS_PORT || 9091;
server.listen(port, () => {
  console.log(`Prometheus metrics available at http://localhost:${port}/metrics`);
});

run().catch(console.error);