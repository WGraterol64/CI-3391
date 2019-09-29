/*
CI-3391 Labotatorio de Sistema de Bases de Datos
Proyecto 1
Wilfredo Graterol
15-10639
Schema creation and data import
*/

/* Temporary table to import required data*/
CREATE temporary TABLE cities_raw
(
    id serial PRIMARY KEY,
    name character varying(50) NOT NULL,
    name_ascii character varying(50) NOT NULL,
    latitude float NOT NULL,
    longitude float NOT NULL,
    country character varying(50) NOT NULL,
    iso2 character(2) NOT NULL,
    iso3 character(3) NOT NULL,
    admin_name character(100) NOT NULL,
    capital character(8) NOT NULL,
    population character(15),
    code integer
);

/* Cities table, the main table of the data base*/
CREATE TABLE cities
(
    id serial PRIMARY KEY,
    name character varying(40) NOT NULL,
    latitude float NOT NULL,
    longitude float NOT NULL,
    country character varying(40) NOT NULL,
    population character(15)
);

/* Country table, usefull table for queries*/
CREATE TABLE countries(
    name character varying(50) PRIMARY KEY
);

/* Import data from cvs file into the temporary table*/
\copy cities_raw(name, name_ascii, latitude, longitude, country, iso2, iso3, admin_name, capital, population,code) FROM 'worldcities.csv' DELIMITER ',' CSV HEADER;

/* Inserting into the main table those cities with known population. We'll only import 200 out of the over 12000 cities for the sake of this excercise*/
INSERT INTO cities(name, latitude, longitude, country, population)
SELECT name_ascii, latitude, longitude, country, population 
FROM cities_raw
WHERE population!=''
ORDER BY population ASC
LIMIT 200;

/* We insert the names of the countries in the cities table to the countries table*/
INSERT INTO countries(name)
SELECT DISTINCT country
FROM cities;

/* We drop the temporal table*/
DROP TABLE cities_raw;

/* We cast the population atribute of the cities table as a float. 
We had to use float because some numbers came in the xxxx.0 format*/
ALTER TABLE cities ALTER COLUMN population TYPE float USING (trim(population)::float);

/*We set the country name in each city as a foreign key*/
ALTER TABLE cities ADD FOREIGN KEY (country) REFERENCES countries (name);

