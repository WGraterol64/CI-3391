/*
 CI-3391 Labotatorio de Sistema de Bases de Datos
 Proyecto 2
 Wilfredo Graterol
 15-10639
 Queries
*/

-- Query 1

SELECT customer.*
FROM customer 
JOIN (SELECT city.id AS qid
	  FROM city 
	  JOIN (SELECT delivery_city_id
			FROM placed_order 
			JOIN (SELECT oi0.id, SUM(tm.price*oi0.quant) as tsum
				  FROM item AS tm 
				  JOIN (SELECT po.id, oi.item_id AS item_id0, oi.quantity AS quant
						FROM order_item AS oi 
						JOIN placed_order AS po 
						ON oi.placed_order_id = po.id) AS oi0
				  ON oi0.item_id0 = tm.id
				  GROUP BY oi0.id
				  ORDER BY tsum DESC
				  LIMIT floor((SELECT count(*)
							   FROM placed_order)*0.05)) AS q0 
			ON placed_order.id=q0.id ) AS c1 
	  ON  c1.delivery_city_id = city.id ) AS q 
ON customer.city_id=q.qid;

--Query 2

SELECT c1.*
FROM city AS c1
JOIN (SELECT c0.id AS cid, AVG(delivery_time_actual-delivery_time_planned) AS average
			  FROM city AS c0 JOIN (SELECT delivery_city_id, delivery_time_actual, delivery_time_planned
									FROM placed_order 
									JOIN delivery 
									ON placed_order.id = placed_order_id) AS q0 
			  ON c0.id = q0.delivery_city_id
			  GROUP BY c0.id
			  HAVING AVG(delivery_time_actual-delivery_time_planned) NOTNULL
			  ORDER BY average DESC
			  LIMIT 5) AS q1
ON c1.id = q1.cid;


-- Query 3

SELECT i0.*
FROM item AS i0
JOIN (SELECT q1.item_id, COUNT(*) 	 								-- Contamos el numero de tuplas y ordenamos los resultados, 
																	-- solo sacamos uno de los mayores lo cual es lo que nos interesa.

FROM (SELECT item_id, delivery_time_actual, delivery_time_planned 	-- En este momento tenemos cada item_id con cada uno de sus tiempos
	  FROM order_item 
	  JOIN (SELECT placed_order.id AS poid, delivery_time_actual, delivery_time_planned
			FROM placed_order
			JOIN (SELECT delivery.id AS did, delivery_time_actual, delivery_time_planned, placed_order_id
				  FROM delivery) AS q3 
			ON placed_order.id = q3.placed_order_id ) AS q2
	  ON order_item.placed_order_id = q2.poid
	  WHERE delivery_time_actual>delivery_time_planned AND
	  		delivery_time_actual NOTNULL) AS q1
	  GROUP BY q1.item_id
	  ORDER BY COUNT(*) DESC
	  LIMIT 1) AS q0 												-- Si hay varios que generan la mayor cantidad de retrasos, se retorna uno solo
ON i0.id = q0.item_id;
 