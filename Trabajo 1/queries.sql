/*
CI-3391 Labotatorio de Sistema de Bases de Datos
Proyecto 1
Wilfredo Graterol
15-10639
Queries
*/

/*First query*/
SELECT FIRST.name AS City1, FIRST.population AS Population1, array_to_string(array_agg(SECOND.name),'; ') AS City2, SECOND.population AS Population2
FROM cities FIRST
LEFT JOIN cities SECOND on SECOND.population = (SELECT MAX(population) FROM cities WHERE population<FIRST.population)
GROUP BY FIRST.name, FIRST.population, SECOND.population
ORDER BY FIRST.population;


/*Second query*/
SELECT DISTINCT con.name AS Country, FIRST.latitude AS lat1, SECOND.longitude AS lng1, THIRD.latitude AS lat2, FOURTH.longitude AS lng2
FROM countries AS con, cities FIRST, cities SECOND, cities THIRD, cities FOURTH
WHERE FIRST.latitude = (SELECT MIN(latitude) FROM cities WHERE country = con.name) AND
      SECOND.longitude = (SELECT MIN(longitude) FROM cities WHERE country = con.name) AND
      THIRD.latitude = (SELECT MAX(latitude) FROM cities WHERE country = con.name) AND
      FOURTH.longitude = (SELECT MAX(longitude) FROM cities WHERE country = con.name);

/*Third query*/
/* Credits to strkol@stackoverflow.com  for this distance function*/
CREATE OR REPLACE FUNCTION distance(lat1 FLOAT, lon1 FLOAT, lat2 FLOAT, lon2 FLOAT) RETURNS FLOAT AS $$
DECLARE                                                   
    x float = 111.12 * (lat2 - lat1);                           
    y float = 111.12 * (lon2 - lon1) * cos(lat1 / 92.215);        
BEGIN                                                     
    RETURN sqrt(x * x + y * y);                               
END  
$$ LANGUAGE plpgsql;

SELECT FIRST.name AS city1, FIRST.latitude AS Lat1, FIRST.longitude AS Lng1, SECOND.name AS city2, SECOND.latitude AS Lat2, SECOND.longitude AS Lng2
FROM cities FIRST, cities SECOND
WHERE FIRST.name <> SECOND.name AND
	  distance(FIRST.latitude, FIRST.longitude, second.latitude, second.longitude) = 
	  (SELECT MAX(distance(c1.latitude, c1.longitude, c2.latitude, c2.longitude)) FROM cities c1, cities c2 WHERE c1.name<>c2.name);

/*Fourth query*/
SELECT c0.name AS City, c1.name AS City1, distance(c0.latitude,c0.longitude,c1.latitude,c1.longitude) AS Distance1,
                        c2.name AS City2, distance(c0.latitude,c0.longitude,c2.latitude,c2.longitude) AS Distance2,
                        c3.name AS City3, distance(c0.latitude,c0.longitude,c3.latitude,c3.longitude) AS Distance3
FROM cities c0, cities c1, cities c2, cities c3
WHERE c1.name<>c2.name AND c1.name<>c3.name AND c2.name<>c3.name
	  AND distance(c0.latitude,c0.longitude,c1.latitude,c1.longitude)>= distance(c0.latitude,c0.longitude,c2.latitude,c2.longitude)
	  AND distance(c0.latitude,c0.longitude,c2.latitude,c2.longitude) >= distance(c0.latitude,c0.longitude,c3.latitude,c3.longitude)
      AND c1.name IN 
	  (SELECT c4.name 
	   FROM cities c4
	   WHERE c0.name<>c4.name
	   ORDER BY distance(c0.latitude,c0.longitude,c4.latitude,c4.longitude)
	   LIMIT 3) AND
       c2.name IN 
	  (SELECT c4.name 
	   FROM cities c4
	   WHERE c0.name<>c4.name
	   ORDER BY distance(c0.latitude,c0.longitude,c4.latitude,c4.longitude)
	   LIMIT 3) AND
       c3.name IN 
	  (SELECT c4.name 
	   FROM cities c4
	   WHERE c0.name<>c4.name
	   ORDER BY distance(c0.latitude,c0.longitude,c4.latitude,c4.longitude)
	   LIMIT 3);