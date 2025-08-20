-- V1__baseline.sql (PostgreSQL)
-- Creates customer_feedback table + summary view under sales schema

CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE IF NOT EXISTS sales.customer_feedback (
    feedback_id     SERIAL PRIMARY KEY,
    customer_id     INT NOT NULL,
    rating          INT CHECK (rating BETWEEN 1 AND 5),
    feedback_text   TEXT,
    submitted_at    TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_customer_feedback_customer FOREIGN KEY (customer_id)
        REFERENCES sales.customer(customerid) ON DELETE CASCADE
);

DROP VIEW IF EXISTS sales.customer_feedback_summary;

CREATE VIEW sales.customer_feedback_summary AS
SELECT
    c.customerid,
    c.accountnumber,
    f.feedback_id,
    f.rating,
    f.feedback_text,
    f.submitted_at
FROM sales.customer c
LEFT JOIN sales.customer_feedback f ON c.customerid = f.customer_id;