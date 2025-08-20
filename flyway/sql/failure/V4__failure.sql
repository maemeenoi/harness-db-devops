-- Intentionally fails by trying to add existing column again

ALTER TABLE sales.customer_feedback ADD status VARCHAR(20) NOT NULL DEFAULT 'active';