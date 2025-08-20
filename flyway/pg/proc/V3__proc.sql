-- V3__proc.sql (PostgreSQL)
-- Creates function to get recent feedback by territory

DROP FUNCTION IF EXISTS sales.get_recent_feedback_by_region();

CREATE FUNCTION sales.get_recent_feedback_by_region()
RETURNS TABLE (
    customer_id INT,
    territory_id INT,
    rating INT,
    feedback_text TEXT,
    submitted_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.customerid,
    c.territoryid,
    f.rating,
    f.feedback_text,
    f.submitted_at
  FROM sales.customer c
  JOIN sales.customer_feedback f ON c.customerid = f.customer_id
  WHERE f.submitted_at > NOW() - INTERVAL '30 days'
  ORDER BY f.submitted_at DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;