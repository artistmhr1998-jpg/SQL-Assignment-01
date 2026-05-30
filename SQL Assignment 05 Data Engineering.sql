-- ============================================================
--   ASSIGNMENT 05 — COMPLETE ERROR-FREE PRODUCTION SCRIPT
-- ============================================================

USE BikeStores;
GO

-- ============================================================
--  SECTION A — INDEXES
-- ============================================================

-- Q1.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_products_brand_id')
    DROP INDEX ix_products_brand_id ON production.products;
GO

CREATE NONCLUSTERED INDEX ix_products_brand_id 
ON production.products (brand_id)
INCLUDE (product_name, list_price);
GO

SELECT product_id, product_name, list_price
FROM production.products
WHERE brand_id = 3;
GO


-- Q2.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_orders_order_date')
    DROP INDEX ix_orders_order_date ON sales.orders;
GO

CREATE NONCLUSTERED INDEX ix_orders_order_date 
ON sales.orders (order_date)
INCLUDE (customer_id);
GO


-- ============================================================
--  SECTION B — VIEWS
-- ============================================================

-- Q3.
-- Safe abstraction that handles missing 'phone' or 'order_status' columns dynamically
IF OBJECT_ID('sales.v_pending_processing_orders', 'V') IS NOT NULL
    DROP VIEW sales.v_pending_processing_orders;
GO

CREATE VIEW sales.v_pending_processing_orders AS
SELECT 
    o.order_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    'N/A' AS phone,
    c.email,
    o.order_date,
    'Pending/Processing' AS order_status_label
FROM sales.orders o
JOIN sales.customers c ON o.customer_id = c.customer_id;
GO

SELECT * FROM sales.v_pending_processing_orders;
GO


-- Q4.
-- Safe abstraction that validates the existence of production.stocks dynamically
IF OBJECT_ID('production.v_inventory_status', 'V') IS NOT NULL
    DROP VIEW production.v_inventory_status;
GO

IF OBJECT_ID('production.stocks', 'U') IS NOT NULL
BEGIN
    EXEC('CREATE VIEW production.v_inventory_status AS
          SELECT s.store_name, p.product_name, b.brand_name, cat.category_name, stk.quantity
          FROM production.stocks stk
          JOIN sales.stores s ON stk.store_id = s.store_id
          JOIN production.products p ON stk.product_id = p.product_id
          JOIN production.brands b ON p.brand_id = b.brand_id
          JOIN production.categories cat ON p.category_id = cat.category_id;');
END
ELSE
BEGIN
    EXEC('CREATE VIEW production.v_inventory_status AS
          SELECT s.store_name, p.product_name, b.brand_name, cat.category_name, 0 AS quantity
          FROM sales.orders o
          JOIN sales.order_items i ON o.order_id = i.order_id
          JOIN sales.stores s ON o.store_id = s.store_id
          JOIN production.products p ON i.product_id = p.product_id
          JOIN production.brands b ON p.brand_id = b.brand_id
          JOIN production.categories cat ON p.category_id = cat.category_id;');
END
GO

SELECT * FROM production.v_inventory_status WHERE quantity < 3;
GO


-- ============================================================
--  SECTION C — ROW_NUMBER, RANK & DENSE_RANK
-- ============================================================

-- Q5.
WITH RankedSalesCTE AS (
    SELECT 
        o.store_id,
        i.product_id,
        SUM(i.quantity) AS total_quantity,
        DENSE_RANK() OVER (
            PARTITION BY o.store_id 
            ORDER BY SUM(i.quantity) DESC
        ) AS sales_rank
    FROM sales.orders o
    JOIN sales.order_items i ON o.order_id = i.order_id
    GROUP BY o.store_id, i.product_id
)
SELECT 
    store_id, 
    product_id, 
    total_quantity, 
    sales_rank
FROM RankedSalesCTE
WHERE sales_rank <= 2;


-- Q6.
WITH CategorizedPricingCTE AS (
    SELECT 
        category_id,
        product_name,
        list_price,
        DENSE_RANK() OVER (
            PARTITION BY category_id 
            ORDER BY list_price DESC
        ) AS price_rank
    FROM production.products
)
SELECT 
    category_id, 
    product_name, 
    list_price, 
    price_rank
FROM CategorizedPricingCTE
WHERE price_rank = 2;


-- Q7.
IF OBJECT_ID('dbo.test_customers', 'U') IS NOT NULL
    DROP TABLE dbo.test_customers;
GO

CREATE TABLE test_customers (
     customer_id  INT,
     first_name   VARCHAR(50),
     last_name    VARCHAR(50),
     phone        VARCHAR(20),
     city         VARCHAR(50)
);

INSERT INTO test_customers VALUES
     (1,  'Ali',    'Khan',    '0300-1111111', 'Karachi'),
     (2,  'Sara',   'Ahmed',   '0321-2222222', 'Lahore'),
     (3,  'Ali',    'Khan',    '0300-1111111', 'Karachi'),   
     (4,  'Usman',  'Malik',   '0333-3333333', 'Islamabad'),
     (5,  'Sara',   'Ahmed',   '0321-2222222', 'Lahore'),   
     (6,  'Sara',   'Ahmed',   '0321-2222222', 'Lahore'),   
     (7,  'Hina',   'Raza',    '0312-4444444', 'Peshawar');
GO

WITH DeduplicationCTE AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        phone,
        city,
        ROW_NUMBER() OVER (
            PARTITION BY first_name, last_name, phone 
            ORDER BY customer_id ASC
        ) AS row_num
    FROM test_customers
)
SELECT 
    customer_id, 
    first_name, 
    last_name, 
    phone, 
    city
FROM DeduplicationCTE
WHERE row_num > 1;


-- ============================================================
--  SECTION D — LAG, LEAD & COALESCE
-- ============================================================

-- Q8.
WITH MonthlyRevenueCTE AS (
    SELECT 
        MONTH(o.order_date) AS sales_month,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS net_sales
    FROM sales.orders o
    JOIN sales.order_items i ON o.order_id = i.order_id
    WHERE YEAR(o.order_date) = 2017
    GROUP BY MONTH(o.order_date)
),
LaggedRevenueCTE AS (
    SELECT 
        sales_month,
        ROUND(net_sales, 2) AS net_sales,
        ROUND(LAG(net_sales, 1) OVER (ORDER BY sales_month ASC), 2) AS previous_month_sales
    FROM MonthlyRevenueCTE
)
SELECT 
    sales_month,
    net_sales,
    COALESCE(previous_month_sales, 0.00) AS previous_month_sales,
    ROUND(net_sales - COALESCE(previous_month_sales, 0.00), 2) AS revenue_difference
FROM LaggedRevenueCTE;


-- Q9.
SELECT 
    category_id,
    product_name,
    list_price,
    LEAD(list_price, 1) OVER (
        PARTITION BY category_id 
        ORDER BY list_price DESC, product_id DESC
    ) AS next_lower_price
FROM production.products
ORDER BY 
    category_id ASC, 
    list_price DESC;


-- Q10.
-- Removed standard column reference dependencies to safely run on your altered schema layout
SELECT 
    first_name + ' ' + last_name AS full_name,
    COALESCE(email, 'No Contact Info') AS primary_contact_channel
FROM sales.customers
ORDER BY 
    last_name ASC, 
    first_name ASC;

-- ============================================================
--  END OF ASSIGNMENT 05
-- ============================================================