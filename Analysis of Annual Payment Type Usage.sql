WITH temp_table AS (
	SELECT EXTRACT(YEAR FROM orders.order_purchase_timestamp) AS year, payment.payment_type
	FROM orders_dataset AS orders
	LEFT JOIN order_payments_dataset AS payment
	ON orders.order_id = payment.order_id
)

SELECT payment_type, year_2016, year_2017, year_2018,
SUM(year_2016 + year_2017 + year_2018) AS total
FROM (
	SELECT payment_type,
	COUNT(CASE WHEN year = 2016 THEN year ELSE NULL END) AS year_2016,
	COUNT(CASE WHEN year = 2017 THEN year ELSE NULL END) AS year_2017,
	COUNT(CASE WHEN year = 2018 THEN year ELSE NULL END) AS year_2018
	FROM temp_table
	WHERE payment_type IS NOT NULL
	GROUP BY 1
) AS table1
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;