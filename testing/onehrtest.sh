#!/bin/bash

echo "Generating test data for CDC pipeline..."

# 20 Inserts
echo "Creating 20 users..."
for i in {1..20}; do
  mysql -h 127.0.0.1 -P 4000 -u root testdb -e "INSERT INTO users (username, email, password) VALUES ('testuser$i', 'test$i@example.com', 'pass$i');" 2>/dev/null
  echo "Inserted user $i"
  sleep 2
done

# 10 Updates
echo "Updating 10 users..."
for i in {1..10}; do
  mysql -h 127.0.0.1 -P 4000 -u root testdb -e "UPDATE users SET email='updated$i@example.com' WHERE username='testuser$i';" 2>/dev/null
  echo "Updated user $i"
  sleep 2
done

# 5 Deletes
echo "Deleting 5 users..."
for i in {1..5}; do
  mysql -h 127.0.0.1 -P 4000 -u root testdb -e "DELETE FROM users WHERE username='testuser$i';" 2>/dev/null
  echo "Deleted user $i"
  sleep 2
done

echo "✓ Test data generation complete!"
echo "Results: 20 inserts, 10 updates, 5 deletes"
echo "Check Grafana dashboard at http://localhost:3000"