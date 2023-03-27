WITH join_table AS (
	SELECT orders.order_status AS status,
	orders.order_purchase_timestamp AS order_date,
	product.product_category_name AS category,
	(items.price + items.freight_value) AS revenue
	FROM orders_dataset AS orders
	LEFT JOIN order_items_dataset AS items
	ON orders.order_id = items.order_id
	LEFT JOIN product_dataset AS product
	ON items.product_id = product.product_id
), revenue_table AS (
	SELECT EXTRACT(YEAR FROM order_date) AS year, SUM(revenue) AS total_revenue
	FROM join_table
	WHERE status = 'delivered'
	AND order_date IS NOT NULL
	GROUP BY 1
), num_canceled_table AS (
	SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
	COUNT(order_status) AS num_canceled
	FROM orders_dataset
	WHERE order_status = 'canceled'
	GROUP BY 1
), revenue_category_table AS (
	SELECT year, category, revenue_per_category
	FROM (
		SELECT EXTRACT(YEAR FROM order_date) AS year, category,
		SUM(revenue) AS revenue_per_category,
		RANK() OVER (PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY SUM(revenue) DESC) AS ranking
		FROM join_table
		WHERE status = 'delivered'
		GROUP BY 1, 2) AS top_revenue_per_category
	WHERE ranking = 1
), canceled_category_table AS (
	SELECT year, category, num_canceled_per_category
	FROM (
		SELECT EXTRACT(YEAR FROM order_date) AS year, category,
		COUNT(status) AS num_canceled_per_category,
		RANK() OVER (PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY COUNT(status) DESC) AS ranking
		FROM join_table
		WHERE status = 'canceled' AND category IS NOT NULL
		GROUP BY 1, 2) AS top_canceled_per_category
	WHERE ranking = 1
)

SELECT revenue_table.year, revenue_table.total_revenue, num_canceled_table.num_canceled,
revenue_category_table.category AS top_revenue_category,
revenue_category_table.revenue_per_category,
canceled_category_table.category AS top_canceled_category,
canceled_category_table.num_canceled_per_category
FROM revenue_table
JOIN num_canceled_table
ON revenue_table.year = num_canceled_table.year
JOIN revenue_category_table
ON revenue_table.year = revenue_category_table.year
JOIN canceled_category_table
ON revenue_table.year = canceled_category_table.year
ORDER BY 1;
