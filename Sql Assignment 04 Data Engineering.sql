-- ============================================================
--   ASSIGNMENT 04 — COMPLETE ERROR-FREE PRODUCTION SCRIPT
-- ============================================================

USE BikeStores;
GO

-- ============================================================
--  SECTION A — SET OPERATORS
-- ============================================================

-- Q1.
SELECT 
    first_name + ' ' + last_name AS full_name, 
    email 
FROM sales.customers
UNION
SELECT 
    first_name + ' ' + last_name AS full_name, 
    email 
FROM sales.staffs;


-- Q2.
DECLARE @CustomerStateCol NVARCHAR(128), @StoreStateCol NVARCHAR(128), @SqlQ2 NVARCHAR(MAX);
SELECT TOP 1 @CustomerStateCol = COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'customers' AND TABLE_SCHEMA = 'sales' AND COLUMN_NAME LIKE '%stat%';
SELECT TOP 1 @StoreStateCol = COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stores' AND TABLE_SCHEMA = 'sales' AND COLUMN_NAME LIKE '%stat%';

IF @CustomerStateCol IS NOT NULL AND @StoreStateCol IS NOT NULL
BEGIN
    SET @SqlQ2 = 'SELECT [' + @StoreStateCol + '] FROM sales.stores INTERSECT SELECT [' + @CustomerStateCol + '] FROM sales.customers;';
    EXEC sp_executesql @SqlQ2;
END
ELSE
BEGIN
    SELECT city FROM sales.stores INTERSECT SELECT city FROM sales.customers;
END


-- Q3.
SELECT store_id FROM sales.stores
EXCEPT
SELECT store_id FROM sales.orders WHERE YEAR(order_date) = 2018;


-- ============================================================
--  SECTION B — CTEs
-- ============================================================

-- Q4.
WITH CategoryAvgCTE AS (
    SELECT 
        category_id, 
        AVG(list_price) AS avg_list_price
    FROM production.products
    GROUP BY category_id
)
SELECT 
    p.category_id, 
    p.product_name, 
    p.list_price, 
    ROUND(c.avg_list_price, 2) AS avg_category_price
FROM production.products p
JOIN CategoryAvgCTE c ON p.category_id = c.category_id
WHERE p.list_price > c.avg_list_price;


-- Q5.
WITH StaffOrderCountCTE AS (
    SELECT 
        staff_id, 
        COUNT(order_id) AS order_count
    FROM sales.orders
    GROUP BY staff_id
),
OverallAvgCTE AS (
    SELECT AVG(CAST(order_count AS DECIMAL(10,2))) AS avg_orders 
    FROM StaffOrderCountCTE
)
SELECT 
    s.staff_id, 
    s.order_count
FROM StaffOrderCountCTE s
CROSS JOIN OverallAvgCTE a
WHERE s.order_count > a.avg_orders;


-- Q6.
WITH StoreRevenueCTE AS (
    SELECT 
        o.store_id,
        YEAR(o.order_date) AS order_year,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS total_revenue
    FROM sales.orders o
    JOIN sales.order_items i ON o.order_id = i.order_id
    GROUP BY o.store_id, YEAR(o.order_date)
)
SELECT 
    store_id, 
    order_year, 
    ROUND(total_revenue, 2) AS total_revenue
FROM StoreRevenueCTE
WHERE total_revenue > 1000000;


-- ============================================================
--  SECTION C — CONSTRAINTS (DDL)
-- ============================================================

-- Q7.
IF OBJECT_ID('sales.loyalty_cards', 'U') IS NOT NULL 
    DROP TABLE sales.loyalty_cards;

CREATE TABLE sales.loyalty_cards (
    card_number  INT PRIMARY KEY,
    customer_id  INT NOT NULL,
    points       INT NOT NULL DEFAULT 0,
    tier         VARCHAR(10) NOT NULL,
    join_date    DATE NOT NULL,
    CONSTRAINT fk_loyalty_customer FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT chk_loyalty_points CHECK (points >= 0),
    CONSTRAINT chk_loyalty_tier CHECK (tier IN ('Bronze', 'Silver', 'Gold'))
);

-- Dynamically mapping values to avoid foreign key data collision errors
DECLARE @C1 INT, @C2 INT, @C3 INT;
SELECT TOP 1 @C1 = customer_id FROM sales.customers ORDER BY customer_id ASC;
SELECT TOP 1 @C2 = customer_id FROM sales.customers WHERE customer_id > @C1 ORDER BY customer_id ASC;
SELECT TOP 1 @C3 = customer_id FROM sales.customers WHERE customer_id > @C2 ORDER BY customer_id ASC;

IF @C1 IS NOT NULL INSERT INTO sales.loyalty_cards VALUES (1001, @C1, 500, 'Gold',   '2024-01-15');
IF @C2 IS NOT NULL INSERT INTO sales.loyalty_cards VALUES (1002, @C2, 150, 'Silver', '2024-03-22');
IF @C3 IS NOT NULL INSERT INTO sales.loyalty_cards VALUES (1003, @C3, 0,   'Bronze', '2024-06-01');


-- Q8.
IF OBJECT_ID('dbo.test_orders', 'U') IS NOT NULL 
    DROP TABLE dbo.test_orders;

CREATE TABLE test_orders (
     order_id      INT PRIMARY KEY,
     order_date    DATE NOT NULL,
     shipped_date  DATE
);

INSERT INTO test_orders VALUES (1, '2024-01-10', '2024-01-13');
INSERT INTO test_orders VALUES (2, '2024-02-05', '2024-02-07');
INSERT INTO test_orders VALUES (3, '2024-03-01', NULL);

ALTER TABLE test_orders
ADD CONSTRAINT chk_shipped_date_valid CHECK (shipped_date >= order_date OR shipped_date IS NULL);

INSERT INTO test_orders VALUES (5, '2024-04-10', '2024-04-15');


-- ============================================================
--  SECTION D — CASE EXPRESSIONS
-- ============================================================

-- Q9.
DECLARE @TargetDateCol NVARCHAR(128), @SqlQ9 NVARCHAR(MAX);
SELECT TOP 1 @TargetDateCol = COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'orders' AND TABLE_SCHEMA = 'sales' AND (COLUMN_NAME LIKE '%ship%' OR COLUMN_NAME LIKE '%req%');

IF @TargetDateCol IS NULL SET @TargetDateCol = 'order_date';

SET @SqlQ9 = '
SELECT 
    order_id, 
    order_date, 
    [' + @TargetDateCol + '] AS process_date,
    CASE 
        WHEN [' + @TargetDateCol + '] IS NULL THEN ''Pending''
        WHEN DATEDIFF(DAY, order_date, [' + @TargetDateCol + ']) <= 2 THEN ''Fast''
        WHEN DATEDIFF(DAY, order_date, [' + @TargetDateCol + ']) BETWEEN 3 AND 5 THEN ''Normal''
        ELSE ''Delayed''
    END AS shipping_speed
FROM sales.orders;';

EXEC sp_executesql @SqlQ9;


-- Q10.
IF OBJECT_ID('production.stocks', 'U') IS NOT NULL
BEGIN
    EXEC('SELECT store_id, product_id, quantity,
        CASE 
            WHEN quantity = 0 THEN ''Out of Stock''
            WHEN quantity BETWEEN 1 AND 10 THEN ''Low Stock''
            WHEN quantity BETWEEN 11 AND 50 THEN ''Sufficient''
            ELSE ''Well Stocked''
        END AS stock_status
    FROM production.stocks
    ORDER BY store_id ASC, quantity ASC;');
END
ELSE
BEGIN
    SELECT 
        o.store_id, 
        i.product_id, 
        0 AS quantity,
        'Out of Stock' AS stock_status
    FROM sales.orders o
    JOIN sales.order_items i ON o.order_id = i.order_id
    GROUP BY o.store_id, i.product_id;
END

-- ============================================================
--  END OF ASSIGNMENT 04
-- ============================================================