WITH temp_table AS (
	SELECT cust.customer_unique_id AS cust_id, orders.order_id,
	EXTRACT(YEAR FROM orders.order_purchase_timestamp) order_year,
	EXTRACT(MONTH FROM orders.order_purchase_timestamp) order_month
	FROM customers_dataset AS cust
	INNER JOIN orders_dataset AS orders
	ON cust.customer_id = orders.customer_id
), MAU_table AS (
	SELECT order_year, ROUND(AVG(active_users), 2) AS avg_mau
	FROM (SELECT order_year, order_month, COUNT(DISTINCT cust_id) AS active_users
		  FROM temp_table
		  GROUP BY 1, 2
		  HAVING COUNT(order_id) > 0) AS monthly_order_count
	GROUP BY 1
), new_cust_table AS (
	SELECT first_order_year, COUNT(cust_id) AS new_cust
	FROM (
		SELECT cust_id, MIN(order_year) first_order_year
		FROM temp_table
		GROUP BY 1) AS count_table
	GROUP BY 1
), repeat_cust_table AS (
	SELECT order_year, COUNT(cust_id) AS repeat_cust
	FROM (SELECT order_year, cust_id, COUNT(order_id) AS order_count
		  FROM temp_table
		  GROUP BY 1, 2) AS count_table
	WHERE order_count > 1
	GROUP BY 1   	
), avg_order_table AS (
	SELECT order_year, ROUND(AVG(order_count), 2) AS avg_order
	FROM (SELECT order_year, cust_id, COUNT(order_id) AS order_count
		  FROM temp_table
		  GROUP BY 1, 2) AS count_table
	GROUP BY 1   	
)
 
SELECT MAU_table.order_year, avg_mau, new_cust, repeat_cust, avg_order
FROM MAU_table
INNER JOIN new_cust_table
ON MAU_table.order_year = new_cust_table.first_order_year
INNER JOIN repeat_cust_table
ON MAU_table.order_year = repeat_cust_table.order_year
INNER JOIN avg_order_table
ON MAU_table.order_year = avg_order_table.order_year
ORDER BY MAU_table.order_year ASC;
