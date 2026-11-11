-- Runs ONCE, only when the data volume is empty (first start)
CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  text TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
INSERT INTO messages (text) VALUES ('Hello from PostgreSQL (Tier 3)!');
