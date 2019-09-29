/*
 CI-3391 Labotatorio de Sistema de Bases de Datos
 Proyecto 2
 Wilfredo Graterol
 15-10639
 Stored Procedures
*/
-- Function to get starting point of sequence
CREATE OR REPLACE FUNCTION start_index(input_table text)
    RETURNS TABLE (col_1 bigint) AS $$
BEGIN
    RETURN QUERY EXECUTE
        format('SELECT COUNT(*) FROM %I', input_table);
END;
$$ LANGUAGE plpgsql;

-- function to get a random id of a relation
CREATE OR REPLACE FUNCTION rand_int(input_table text)
    RETURNS TABLE (col_1 int) AS $$
BEGIN
    RETURN QUERY EXECUTE
        format('SELECT floor(random() * ((SELECT MAX(%I.id) FROM %I)- (SELECT MIN(%I.id) FROM %I)) + (SELECT MIN(%I.id) FROM %I))::int', input_table, input_table, input_table, input_table, input_table, input_table);
END;
$$ LANGUAGE plpgsql; 

--create orders, item orders and deliveries
CREATE OR REPLACE FUNCTION create_orders(n int, a int)
    RETURNS VOID AS $$
DECLARE
	dir int; cust int; oid int; j int; onum int; iid int; it int; quant int;
	date timestamp; timePlaced timestamp; timePlanned timestamp; timeActual timestamp;
	address text;
BEGIN
	-- insertamos tupla en placed_order
    FOR i IN 1..n LOOP
		onum := a + floor((random()*5 - 2.5))::int;
		j := 0;
		oid := start_index('placed_order')+1;
		cust := rand_int('customer');
		date := (SELECT time_confirmed FROM customer WHERE customer.id = cust);
		timePlaced := date + (random() * (date+'30 days' - date));
		timePlanned := timePlaced + (random() * (timePlaced+'30 days' - timePlaced));

		-- decidimos el lugar de envio
		IF (random()>0.90) THEN
			dir := rand_int('city');
		ELSE
			dir := (SELECT delivery_city_id FROM customer WHERE id = cust);
		END IF;

		-- podemos probabilidad de retraso aleatoria
		IF (random()<0.50) THEN
			timeActual := timePlanned;
		ELSE
			timeActual := timePlanned + (random() * (timePlanned+'10 days' - timePlanned));
		END IF;

		address := (SELECT postal_code ||' '|| city_name FROM city WHERE city.id = dir);

		INSERT INTO placed_order VALUES (oid,cust, timePlaced, NULL, dir, address, NULL, NULL) ;

		-- Damos la opcion de que la orden no haya llegado poniendo null en el valor de tiempo de llegada real
		IF (random()<0.75) THEN
			INSERT INTO delivery VALUES (start_index('delivery')+1, timePlanned, timeActual, NULL, oid, NULL);
		ELSE
			INSERT INTO delivery VALUES (start_index('delivery')+1, timePlanned, NULL, NULL, oid, NULL);
		END IF;

		-- Creamos las ordenes por item
		WHILE j<=onum LOOP
			iid := start_index('order_item')+1;
			it := rand_int('item');
			quant := ABS(ceil((random()*5 - 2.5))::int);
			IF quant=0 THEN
				CONTINUE;
			END IF;
			INSERT INTO order_item VALUES (iid, oid, it, quant::decimal(10,3), quant*(SELECT price FROM item WHERE item.id = it));
			j := j + quant;
		END LOOP;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- creates customers
CREATE OR REPLACE FUNCTION create_customers(n int)
    RETURNS VOID AS $$
DECLARE
	cid int; cityId int; deliverCityId int; s int;
	insertedTime timestamp; confirmDay timestamp; 
	name text; surname text; userName text; psswd text; confirmCode text; email text;
	ready boolean;
BEGIN
	-- insertamos tupla en placed_order
    FOR i IN 1..n LOOP
		cid := start_index('customer')+1;
		name := (SELECT names.name FROM names 
				 WHERE names.id= (SELECT rand_int('names')));
		surname := (SELECT surnames.surname FROM surnames 
					WHERE surnames.id= (SELECT rand_int('surnames')));
		ready = FALSE;
		WHILE NOT ready LOOP
			s := (SELECT floor((SELECT MIN(u.id) FROM userNames AS u) + random()*(SELECT MAX(u.id) FROM userNames AS u ))::int);
			IF NOT EXISTS (SELECT * FROM customer JOIN userNames ON customer.user_name=userNames.userName WHERE userNames.id = s) THEN
				ready := 1;
			END IF;
		END LOOP;
		userName := (SELECT userNames.userName 
					 FROM userNames
					 WHERE userNames.id = s);
		psswd := substr(md5(random()::text), 5, floor(random() * 20 + 5)::int);
		insertedTime := NOW();
		confirmCode :=  md5(random()::text);
		confirmDay := NOW() + (random() * (NOW()+'15 days' - NOW()));
		email := name || '_' || surname || floor(random()*100)::text || '@gmail.com';
		cityId := rand_int('city');
		IF (random() > 0.80) THEN
			deliverCityId := rand_int('city');
		ELSE
			deliverCityId := cityId;
		END IF;
		INSERT INTO customer VALUES (cid, name, surname, userName, psswd, insertedTime, confirmCode, confirmDay, email, NULL, cityId, NULL, deliverCityId, NULL);
	END LOOP;
END;

$$ LANGUAGE plpgsql;

-- Create items
CREATE OR REPLACE FUNCTION create_items(n int)
	RETURNS VOID AS $$
DECLARE
	name text;
	price int; unit int; r int; i int;
BEGIN
	i := 0;
	WHILE i<n LOOP
		r := rand_int('items');
		IF EXISTS(SELECT * FROM item WHERE item.item_name=(SELECT items.item_name FROM items WHERE items.id = r )) THEN
			CONTINUE;
		END IF;
		name := (SELECT items.item_name FROM items WHERE items.id = r );
		price := (SELECT items.price FROM items WHERE items.id = r );
		unit := (SELECT items.unit FROM items WHERE items.id = r );
		INSERT INTO item VALUES (1+start_index('item'), name, price, NULL, NULL, unit);
		i := i+1;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- function to fill database
CREATE OR REPLACE PROCEDURE spCreateTestData(number_of_customers int, number_of_orders int, number_of_items int,avg_items_per_order int)
LANGUAGE  plpgsql
AS $$
BEGIN
    -- add items
PERFORM create_items(number_of_items);

-- add customers
PERFORM create_customers(number_of_customers);

-- add orders
PERFORM create_orders(number_of_orders, avg_items_per_order);
END;
$$;