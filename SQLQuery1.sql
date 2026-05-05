-- =========================================
-- INSERT SAMPLE DATA
-- =========================================
INSERT INTO customers VALUES
(1,'Ali','Khan','Los Angeles','CA','123456'),
(2,'Ahmed','Raza','Houston','TX',NULL),
(3,'Sara','Ali','San Diego','CA','987654');

INSERT INTO products VALUES
(1,'Bike A',1,1,2019,600),
(2,'Bike B',1,2,2020,1200),
(3,'Bike C',2,1,2021,300),
(4,'Bike D',2,2,2019,1500),
(5,'Bike E',3,1,2020,800);

-- =========================================
-- QUESTION 1
-- =========================================
SELECT first_name, last_name, city, phone
FROM customers
WHERE state = 'CA' AND phone IS NOT NULL;

-- =========================================
-- QUESTION 2
-- =========================================
SELECT product_id, product_name, model_year, list_price
FROM products
ORDER BY model_year DESC, list_price ASC;

-- =========================================
-- QUESTION 3
-- =========================================

-- Part a
SELECT TOP 5 product_name, list_price
FROM products
ORDER BY list_price DESC;

-- Part b
SELECT TOP 5 PERCENT *
FROM products
ORDER BY list_price ASC;

-- =========================================
-- QUESTION 4
-- =========================================

SELECT * FROM products
ORDER BY list_price DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

SELECT * FROM products
ORDER BY list_price DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

SELECT * FROM products
ORDER BY list_price DESC
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;

-- =========================================
-- QUESTION 5
-- =========================================

SELECT DISTINCT state FROM customers ORDER BY state;

SELECT DISTINCT state, city FROM customers ORDER BY state, city;

SELECT COUNT(DISTINCT model_year) AS total_model_years FROM products;

-- =========================================
-- QUESTION 6
-- =========================================
SELECT product_id, product_name, brand_id, category_id, list_price
FROM products
WHERE list_price BETWEEN 500 AND 1500
  AND (model_year = 2019 OR model_year = 2020)
ORDER BY list_price ASC;