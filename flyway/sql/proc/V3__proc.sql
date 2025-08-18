IF OBJECT_ID('shop.upsert_customer','P') IS NOT NULL DROP PROCEDURE shop.upsert_customer;
GO
CREATE PROCEDURE shop.upsert_customer
  @full_name NVARCHAR(120),
  @email NVARCHAR(255)
AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT 1 FROM shop.customers WHERE email=@email)
    UPDATE shop.customers SET full_name=@full_name WHERE email=@email;
  ELSE
    INSERT INTO shop.customers(full_name,email) VALUES (@full_name,@email);
END;
GO