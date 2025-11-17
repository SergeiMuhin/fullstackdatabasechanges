USE testdb;

-- Create default admin user
INSERT INTO users (username, email, password) VALUES 
('admin', 'admin@example.com', SHA2('admin123', 256));

-- Insert some test data
INSERT INTO users (username, email, password) VALUES 
('john_doe', 'john@example.com', SHA2('password123', 256)),
('jane_smith', 'jane@example.com', SHA2('password456', 256));

INSERT INTO products (name, price, stock) VALUES 
('Laptop', 999.99, 50),
('Mouse', 29.99, 200),
('Keyboard', 79.99, 150);

INSERT INTO orders (user_id, product_name, amount, status) VALUES 
(1, 'Laptop', 999.99, 'completed'),
(2, 'Mouse', 29.99, 'pending');