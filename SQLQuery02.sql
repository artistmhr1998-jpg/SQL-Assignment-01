USE BikeStores;
GO

-- Question 1
SELECT p.product_name, p.list_price, c.category_name
FROM production.products p
JOIN production.categories c ON p.category_id = c.category_id;

-- Question 2
SELECT CONCAT(c.first_name, ' ', c.last_name) AS full_name, o.order_id, o.order_date
FROM sales.customers c
JOIN sales.orders o ON c.customer_id = o.customer_id;

-- Question 3
SELECT p.product_name, p.list_price, c.category_name, b.brand_name
FROM production.products p
JOIN production.categories c ON p.category_id = c.category_id
JOIN production.brands b ON p.brand_id = b.brand_id;

-- Question 4
SELECT p.product_name, oi.order_id, oi.item_id
FROM production.products p
LEFT JOIN sales.order_items oi ON p.product_id = oi.product_id;

-- Question 5
SELECT p.product_id, p.product_name
FROM production.products p
LEFT JOIN sales.order_items oi ON p.product_id = oi.product_id
WHERE oi.order_id IS NULL;

-- Question 6
SELECT s.store_name, s.store_id, o.order_id, o.order_date
FROM sales.stores s
LEFT JOIN sales.orders o ON s.store_id = o.store_id;

-- Question 7
SELECT CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
       CONCAT(m.first_name, ' ', m.last_name) AS manager_name
FROM sales.staffs s
INNER JOIN sales.staffs m ON s.manager_id = m.staff_id;

-- Question 8
SELECT s.store_name, b.brand_name
FROM sales.stores s
CROSS JOIN production.brands b;

-- Question 9
SELECT CONCAT(c.first_name, ' ', c.last_name) AS full_name, o.order_id, o.order_date, p.product_name, oi.list_price
FROM sales.customers c
JOIN sales.orders o ON c.customer_id = o.customer_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
JOIN production.products p ON oi.product_id = p.product_id;
