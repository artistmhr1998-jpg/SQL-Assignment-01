USE BikeStores;
GO

-- Q1: Total orders per customer
SELECT customer_id, COUNT(order_id) AS total_orders
FROM sales.orders
GROUP BY customer_id
ORDER BY total_orders DESC;

-- Q2: Orders per store
SELECT store_id, COUNT(order_id) AS order_count
FROM sales.orders
GROUP BY store_id;

-- Q3: Net revenue per order
SELECT order_id, 
       SUM(quantity * list_price * (1 - discount)) AS revenue
FROM sales.order_items
GROUP BY order_id
ORDER BY revenue DESC;

-- Q4: Avg price per category
SELECT category_id, 
       CAST(AVG(list_price) AS DECIMAL(10,2)) AS average_price
FROM production.products
GROUP BY category_id;

-- Q5: Orders per year
SELECT YEAR(order_date) AS [Year], 
       COUNT(order_id) AS orders_placed
FROM sales.orders
GROUP BY YEAR(order_date)
ORDER BY [Year];

-- Q6: Customers with > 5 orders
SELECT customer_id, COUNT(order_id) AS orders
FROM sales.orders
GROUP BY customer_id
HAVING COUNT(order_id) > 5;

-- Q7: Categories with avg price > 1500
SELECT category_id, AVG(list_price) AS avg_list_price
FROM production.products
GROUP BY category_id
HAVING AVG(list_price) > 1500;

-- Q8: Orders in 2017 (At least 2)
SELECT customer_id, 
       YEAR(order_date) AS order_year, 
       COUNT(order_id) AS total_orders
FROM sales.orders
WHERE YEAR(order_date) = 2017
GROUP BY customer_id, YEAR(order_date)
HAVING COUNT(order_id) >= 2;

-- Q9: Houston orders (Subquery)
SELECT * FROM sales.orders
WHERE customer_id IN (
    SELECT customer_id 
    FROM sales.customers 
    WHERE city = 'Houston'
);

-- Q10: Price > Average
SELECT product_name, list_price
FROM production.products
WHERE list_price > (SELECT AVG(list_price) FROM production.products);

-- Q11: Mountain or Road Bikes (Subquery)
SELECT product_name, list_price
FROM production.products
WHERE category_id IN (
    SELECT category_id 
    FROM production.categories 
    WHERE category_name IN ('Mountain Bikes', 'Road Bikes')
);

-- Q12: Customers with no orders
SELECT customer_id, first_name, last_name
FROM sales.customers
WHERE customer_id NOT IN (SELECT DISTINCT customer_id FROM sales.orders);

-- Q13: Orders per city (Join)
SELECT c.city, COUNT(o.order_id) AS city_orders
FROM sales.customers c
JOIN sales.orders o ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY city_orders DESC;

-- Q14: Orders by staff
SELECT (s.first_name + ' ' + s.last_name) AS staff_full_name, 
       COUNT(o.order_id) AS handled_orders
FROM sales.staffs s
JOIN sales.orders o ON s.staff_id = o.staff_id
GROUP BY s.first_name, s.last_name
ORDER BY handled_orders DESC;

-- Q15: High spending customers (> 10,000)
SELECT (c.first_name + ' ' + c.last_name) AS customer_name, 
       SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
FROM sales.customers c
JOIN sales.orders o ON c.customer_id = o.customer_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY c.first_name, c.last_name
HAVING SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 10000
ORDER BY total_spent DESC;