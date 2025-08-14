CREATE OR REPLACE FUNCTION shop.upsert_customer(p_full_name VARCHAR, p_email VARCHAR)
RETURNS VOID AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM shop.customers WHERE email = p_email) THEN
    UPDATE shop.customers SET full_name = p_full_name WHERE email = p_email;
  ELSE
    INSERT INTO shop.customers(full_name,email) VALUES (p_full_name,p_email);
  END IF;
END;
$$ LANGUAGE plpgsql;