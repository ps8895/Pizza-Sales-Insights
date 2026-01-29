-- KPI Analysis

-- a)	TOTAL REVENUE 
SELECT 
    ROUND(SUM(OD.quantity * P.price), 2) AS Total_revenue
FROM
    orders_details OD
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id;
    
-- b) TOTAL ORDERS PLACED

SELECT 
    COUNT(DISTINCT order_id) AS total_orders
FROM
    orders;

-- c)	TOTAL PIZZAS SOLD

SELECT 
    SUM(quantity) AS Total_pizzas_sold
FROM
    orders_details;

-- d)	AVERAGE ORDER VALUE

SELECT 
    ROUND(SUM(OD.quantity * P.price) / COUNT(DISTINCT O.order_id),
            2) AS Avg_order_value
FROM
    orders_details OD
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id
        JOIN
    orders O ON O.order_id = OD.order_id;

-- e)	AVERAGE PIZZAS PER ORDER

SELECT 
    ROUND(SUM(quantity) / COUNT(DISTINCT O.order_id),
            2) AS Avg_pizza_per_orders
FROM
    orders_details OD
        JOIN
    orders O ON OD.order_id = O.order_id;
    
-- f)	AVERAGE NUMBER OF PIZZAS ORDERED PER DAY

WITH Daywise_pizzas AS
(SELECT order_date, SUM(OD.quantity) AS total FROM orders O 
JOIN orders_details OD ON O.order_id = OD.order_id
GROUP BY order_date
)
SELECT ROUND(AVG(total),0) AS "Avg pizza per day" FROM Daywise_pizzas;

-- g)	MOST ORDERED PIZZA

SELECT 
    PT.name AS Most_ordered_pizza
FROM
    orders_details OD
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id
        JOIN
    pizza_types_new_clean PT ON PT.pizza_type_id = P.pizza_type_id
GROUP BY PT.name
ORDER BY SUM(OD.quantity) DESC
LIMIT 1;

-- B.	NUMBER OF ORDERS ACCORIDNG TO PIZZA SIZES

WITH order_new AS
(SELECT p.size, COUNT(DISTINCT order_id) AS pizzas_sold
FROM orders_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY pizzas_sold DESC)
SELECT size, pizzas_sold, pizzas_sold*100/(SELECT SUM(pizzas_sold) FROM order_new) AS percent_pizzas_sold FROM order_new;




-- C.	TOP 5 MOST ORDERED PIZZA AS PER REVENUE

SELECT PT.name AS Top_5_pizzas, ROUND(SUM(OD.quantity*P.price),2) AS Total_revenue
FROM orders_details OD
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id
        JOIN
    pizza_types_new_clean PT ON PT.pizza_type_id = P.pizza_type_id
GROUP BY PT.name
ORDER BY Total_revenue DESC
LIMIT 5;

-- D.	BOTTOM 5 MOST ORDERED PIZZA AS PER REVENUE

SELECT PT.name AS Bottom_5_pizzas, ROUND(SUM(OD.quantity*P.price),2) AS Total_revenue
FROM orders_details OD
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id
        JOIN
    pizza_types_new_clean PT ON PT.pizza_type_id = P.pizza_type_id
GROUP BY PT.name
ORDER BY Total_revenue
LIMIT 5;

-- E.	TOP 10 MOST ORDERED PIZZA

SELECT PT.name AS Top_10_Most_ordered, ROUND(SUM(OD.quantity),2) AS Total_orders
FROM orders_details OD
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id
        JOIN
    pizza_types_new_clean PT ON PT.pizza_type_id = P.pizza_type_id
GROUP BY PT.name
ORDER BY Total_orders DESC
LIMIT 10;

-- F.	DAILY TREND FOR TOTAL ORDERS & REVENUE

SELECT 
    DAYNAME(O.order_date) AS Weekdays,
    COUNT(O.order_id) AS Total_orders,
    ROUND(SUM(P.price*OD.quantity),2) AS Total_revenue,
    RANK() OVER(ORDER BY SUM(P.price*OD.quantity) DESC) AS Ranking_By_revenue
FROM
    orders O
    JOIN orders_details OD 
    ON O.order_id = OD.order_id
    JOIN pizzas P 
    ON P.pizza_id = OD.pizza_id
GROUP BY Weekdays , WEEKDAY(O.order_date)
ORDER BY WEEKDAY(O.order_date);

-- G.	HOURLY TREND FOR ORDERS & REVENUE

SELECT HOUR(O.order_time) AS Daily_hours, 
    COUNT(O.order_id) AS Total_orders,
    ROUND(SUM(P.price*OD.quantity),2) AS Total_revenue,
    RANK() OVER(ORDER BY SUM(P.price*OD.quantity) DESC) AS Ranking_By_revenue
FROM
    orders O
    JOIN orders_details OD 
    ON O.order_id = OD.order_id
    JOIN pizzas P 
    ON P.pizza_id = OD.pizza_id
GROUP BY Daily_hours
ORDER BY Daily_hours;

-- I.	% OF SALES, REVENUE AND QUANTITY BY PIZZA SIZE

SELECT 
    P.size AS Pizza_size,
    COUNT(OD.quantity) AS Total_quantity,
    ROUND(SUM(OD.quantity * P.price), 2) AS Total_revenue,
    CONCAT(CAST(ROUND((SUM(OD.quantity * P.price) / (SELECT 
                                SUM(P.price * OD.quantity)
                            FROM
                                pizzas P
                                    JOIN
                                orders_details OD ON OD.pizza_id = P.pizza_id)) * 100,
                        2)
                AS CHAR),
            '%') AS Revenue_contribution
FROM
    pizzas P
        JOIN
    orders_details OD ON OD.pizza_id = P.pizza_id
GROUP BY P.size
ORDER BY SUM(OD.quantity * P.price) DESC;

-- J.	% OF SALES, REVENUE AND QUANTITY BY PIZZA CATEGORY

SELECT 
    PT.category AS Pizza_category,
    COUNT(OD.quantity) AS Total_quantity,
    ROUND(SUM(OD.quantity * P.price), 2) AS Total_revenue,
    CONCAT(CAST(ROUND((SUM(OD.quantity * P.price) / (SELECT 
                                SUM(P.price * OD.quantity)
                            FROM
                                pizzas P
                                    JOIN
                                orders_details OD ON OD.pizza_id = P.pizza_id)) * 100,
                        2)
                AS CHAR),
            '%') AS Revenue_contribution
FROM
    pizza_types_new_clean PT
        JOIN
    pizzas P ON P.pizza_type_id = PT.pizza_type_id
        JOIN
    orders_details OD ON OD.pizza_id = P.pizza_id
GROUP BY PT.category;

-- K.	CUMULATIVE REVENUE GENERATED OVER MONTHS

SELECT Month,Total_revenue, ROUND(Cumulative_revenue,2) AS REVENUE_CUMULATIVE FROM
(SELECT MONTHNAME(O.order_date) AS Month, ROUND(SUM(P.price*OD.quantity),2) AS Total_revenue,
	SUM(SUM(P.price*OD.quantity)) OVER(ORDER BY MONTH(O.order_date)) AS Cumulative_revenue
	FROM
    orders O
        JOIN
    orders_details OD ON O.order_id = OD.order_id
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id
GROUP BY MONTHNAME(O.order_date), MONTH(O.order_date)
ORDER BY MONTH(O.order_date) ) AS Cumulative
;

-- L.	TOP 3 MOST ORDERED PIZZA TYPES BASED ON REVENUE FOR EACH PIZZA CATEGORY

SELECT category,name, Total_revenue, Category_wise_ranks
FROM
(SELECT PT.category, PT.name, ROUND(SUM(P.price*OD.quantity),2) AS Total_revenue,
RANK() OVER(PARTITION BY PT.category ORDER BY SUM(P.price*OD.quantity) DESC ) AS Category_wise_ranks
FROM
pizza_types_new_clean PT
        JOIN
    pizzas P ON P.pizza_type_id = PT.pizza_type_id
        JOIN
    orders_details OD ON OD.pizza_id = P.pizza_id
GROUP BY PT.category, PT.name
ORDER BY PT.category) AS pizza_ranking
WHERE Category_wise_ranks <4
;
-- Pizza and size with the highest revenue

SELECT 
    PT.name, P.size, ROUND(SUM(P.price * OD.quantity),2) AS Total_revenue
FROM
    orders_details OD
        JOIN
    pizzas P ON OD.pizza_id = P.pizza_id
        JOIN
    pizza_types_new_clean PT ON PT.pizza_type_id = P.pizza_type_id
GROUP BY PT.name , P.size
ORDER BY SUM(P.price * OD.quantity) DESC
LIMIT 5;