CREATE DATABASE tp3_vinos;  /* Con CREATE DATABASE se crea la base de datos wine_reviews,  
                                para almacenar el conjunto de datos. */
USE tp3_vinos;          -- Seleccionamos con USE esta base para trabajar dentro de ella

CREATE TABLE loadtable_wines (
    num_resena VARCHAR(10),
    country VARCHAR(255),
    description TEXT,
    designation VARCHAR (200),
    points VARCHAR(10),
    price VARCHAR(20),
    province VARCHAR(255),
    region_1 VARCHAR(255),
    region_2 VARCHAR(255),
    variety VARCHAR(255),
    winery VARCHAR(255),
    taster_name VARCHAR(255),
    taster_twitter_handle VARCHAR(255),
    title TEXT
);

SELECT COUNT(*) FROM loadtable_wines;  -- chuequeo de que los datos hayan sido cargados  
SELECT * FROM loadtable_wines LIMIT 10;  -- correctamente desde python

-- Se crean la distintas tablas (dimensiones) para que los datos queden normalizados
CREATE TABLE t_country (
    id_country INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100)
);

CREATE TABLE t_province (
    id_province INT AUTO_INCREMENT PRIMARY KEY,
    province_name VARCHAR(200)
);


CREATE TABLE t_variety (
    id_variety INT AUTO_INCREMENT PRIMARY KEY,
    variety_name VARCHAR(150)
);

CREATE TABLE t_winery (
    id_winery INT AUTO_INCREMENT PRIMARY KEY,
    winery_name VARCHAR(200)
);

CREATE TABLE t_taster (
    id_taster INT AUTO_INCREMENT PRIMARY KEY,
    taster_name VARCHAR(150),
    taster_twitter_handle VARCHAR(150)
);

CREATE TABLE wine_reviews (                      -- TABLA DE HECHOS
    id_review INT AUTO_INCREMENT PRIMARY KEY,  -- Contiene las reseñas de vinos y referencias a las dimensiones
    num_resena INT,
    id_country INT,
    id_province INT,
    region_1 VARCHAR(255),
    region_2 VARCHAR(255),
    id_variety INT,
    id_winery INT,
    id_taster INT,
    designation VARCHAR(255),
    points INT,
    price DECIMAL(10,2),
    title VARCHAR(500),
    description TEXT,
    
-- Definición de claves foráneas
    FOREIGN KEY (id_country) REFERENCES t_country(id_country),
    FOREIGN KEY (id_province) REFERENCES t_province(id_province),
    FOREIGN KEY (id_variety) REFERENCES t_variety(id_variety),
    FOREIGN KEY (id_winery) REFERENCES t_winery(id_winery),
    FOREIGN KEY (id_taster) REFERENCES t_taster(id_taster)
);

-- Poblamos las tablas con los datos 
INSERT INTO t_country (country_name)
SELECT DISTINCT TRIM(LOWER(country))     -- Se normalizan los valores usando LOWER() y TRIM() para evitar
FROM loadtable_wines                     -- duplicados por diferencias de formato.
WHERE country IS NOT NULL AND TRIM(country) <> '';

INSERT INTO t_province (province_name)
SELECT DISTINCT TRIM(LOWER(province))
FROM loadtable_wines
WHERE province IS NOT NULL AND TRIM(province) <> '';

INSERT INTO t_variety (variety_name)
SELECT DISTINCT TRIM(LOWER(variety))
FROM loadtable_wines
WHERE variety IS NOT NULL AND TRIM(variety) <> '';

INSERT INTO t_winery (winery_name)
SELECT DISTINCT TRIM(LOWER(winery))
FROM loadtable_wines
WHERE winery IS NOT NULL AND TRIM(winery) <> '';

INSERT INTO t_taster (taster_name, taster_twitter_handle)
SELECT DISTINCT 
    TRIM(LOWER(taster_name)),
    TRIM(LOWER(taster_twitter_handle))
FROM loadtable_wines
WHERE taster_name IS NOT NULL AND TRIM(taster_name) <> '';
 
 -- Se reemplazan valores no validos por NULL para evitar errores
 -- al insertar en la tabla de hechos.
SET SQL_SAFE_UPDATES = 0;

UPDATE loadtable_wines
SET points = NULL
WHERE points NOT REGEXP '^[0-9]+$';

UPDATE loadtable_wines
SET price = NULL
WHERE price NOT REGEXP '^[0-9]+(\.[0-9]+)?$';

truncate table wine_reviews;

/* se realiza la carga de wine_reviews se usa limit para que se carguen la cantidad de datos (filas) que 
hay realmente en el data set */
INSERT INTO wine_reviews (
    num_resena, id_country, id_province, region_1, region_2,
    id_variety, id_winery, id_taster, designation,
    points, price, title, description
)
SELECT
    lw.num_resena,
    tc.id_country,
    tp.id_province,
    lw.region_1,
    lw.region_2,
    tv.id_variety,
    tw.id_winery,
    tt.id_taster,
    lw.designation,
    lw.points,
    lw.price,
    lw.title,
    lw.description
FROM loadtable_wines lw
LEFT JOIN t_country tc 
    ON TRIM(LOWER(lw.country)) = tc.country_name
LEFT JOIN t_province tp 
    ON TRIM(LOWER(lw.province)) = tp.province_name
LEFT JOIN t_variety tv 
    ON TRIM(LOWER(lw.variety)) = tv.variety_name
LEFT JOIN t_winery tw 
    ON TRIM(LOWER(lw.winery)) = tw.winery_name
LEFT JOIN t_taster tt 
    ON TRIM(LOWER(lw.taster_name)) = tt.taster_name
    LIMIT 129971;

SELECT COUNT(*) FROM wine_reviews;     -- chequeo de cantidad de registros cargados

-- Consultas 

-- Cantidad de vinos por pais
SELECT 
    tc.country_name AS pais,
    COUNT(*) AS cantidad_vinos        -- se cuenta cuantas reseñas hay por pais.
FROM wine_reviews wr
LEFT JOIN t_country tc                -- se une la tabla wine_reviews con la tabla country.
    ON wr.id_country = tc.id_country
GROUP BY tc.country_name              -- se agrupan los registros por pais.
ORDER BY cantidad_vinos DESC;         -- ordena los paises con mas vinos a menos.

-- Precio promedio segun el puntaje
SELECT 
    wr.points AS puntaje,                              -- se selecciona el puntaje del vino 
    ROUND(AVG(wr.price), 2) AS precio_promedio        -- calcula el precio promedio de los vinos que tienen mismo puntaje.
FROM wine_reviews wr
WHERE wr.price IS NOT NULL AND wr.points IS NOT NULL  -- se filtran precios nulos para no distorsionar el promedio.
GROUP BY wr.points                                    -- agrupa todos los vinos por puntaje.
ORDER BY wr.points;

-- Bodegas con mas vinos en el dataset
SELECT 
    tw.winery_name AS bodega,
    COUNT(*) AS cantidad_vinos      -- se cuenta cuantos vinos tiene cada bodega en el dataset.
FROM wine_reviews wr
LEFT JOIN t_winery tw                -- se une la tabla wines_reviews con la tabla winery 
    ON wr.id_winery = tw.id_winery   -- para obtener el nombre de cada una.
GROUP BY tw.winery_name              -- se agrupan los vinos por bodega.
ORDER BY cantidad_vinos DESC
limit 25;                            -- se muestran las 25 bodegas con mas vinos

-- Variedades mas comunes en region_1
SELECT 
    wr.region_1 AS region1,
    tv.variety_name AS variedad,
    COUNT(*) AS cantidad_vinos                         -- cantidad de vinos en esa region1 y variedad
FROM wine_reviews wr 
LEFT JOIN t_variety tv                                 -- se une la tabla de variedades
    ON wr.id_variety = tv.id_variety 
WHERE wr.region_1 IS NOT NULL AND wr.region_1 <> ''    -- excluye regiones vacias
GROUP BY wr.region_1, tv.variety_name                  -- agrupa por region y variedad
ORDER BY wr.region_1, cantidad_vinos DESC;             -- ordena por region y frecuencia

-- Variedades mas comunes en region_2
SELECT 
    wr.region_2 AS region2,
    tv.variety_name AS variedad,
    COUNT(*) AS cantidad_vinos
FROM wine_reviews wr
LEFT JOIN t_variety tv 
    ON wr.id_variety = tv.id_variety
WHERE wr.region_2 IS NOT NULL AND wr.region_2 <> ''  
GROUP BY wr.region_2, tv.variety_name
ORDER BY wr.region_2, cantidad_vinos DESC;

-- Precio promedio por pais y variedad
SELECT 
    tc.country_name AS pais, 
    tv.variety_name AS variedad,
    ROUND(AVG(wr.price), 2) AS precio_promedio,   -- calcula el precio promedio de cada variedad dentro de cada pais
    COUNT(*) AS cantidad_vinos
FROM wine_reviews wr
LEFT JOIN t_country tc ON wr.id_country = tc.id_country
LEFT JOIN t_variety tv ON wr.id_variety = tv.id_variety
WHERE wr.price IS NOT NULL    
GROUP BY pais, variedad        
HAVING COUNT(*) >= 20                            -- solo incluye combinaciones con al menos 20 vinos
ORDER BY pais, precio_promedio DESC;

-- Puntaje promedio por pais y variedad
SELECT 
    tc.country_name AS pais,
    tv.variety_name AS variedad,
    ROUND(AVG(wr.points), 2) AS puntaje_promedio,            -- puntaje promedio redondeado
    COUNT(*) AS cantidad_vinos                               -- cantidad de vinos en esa combinacion
FROM wine_reviews wr
LEFT JOIN t_country tc ON wr.id_country = tc.id_country      -- une pais
LEFT JOIN t_variety tv ON wr.id_variety = tv.id_variety      -- une variedad
WHERE wr.points IS NOT NULL                                  -- excluye precios nulos
GROUP BY pais, variedad
HAVING COUNT(*) >= 20                                        -- ailtra combinaciones con al menos 20 reseñas
ORDER BY pais, puntaje_promedio DESC;                        -- ordena por pais y puntaje promedio

-- Precio y puntaje promedio por pais
SELECT 
    tc.country_name AS pais,
    ROUND(AVG(wr.price), 2) AS precio_promedio,                -- precio promedio
    ROUND(AVG(wr.points), 2) AS puntaje_promedio,              -- puntaje promedio
    COUNT(*) AS cantidad_vinos
FROM wine_reviews wr
LEFT JOIN t_country tc ON wr.id_country = tc.id_country
WHERE wr.price IS NOT NULL  
  AND wr.points IS NOT NULL                                    -- toma solo precio y puntaje validos
GROUP BY pais
HAVING COUNT(*) >= 50                                          -- paises con suficiente cantidad de vinos
ORDER BY precio_promedio DESC;                                 -- ordena por precio promedio

-- Ranking de variedades por pais
SELECT 
    tc.country_name AS pais,
    tv.variety_name AS variedad,
    ROUND(AVG(wr.points), 2) AS puntaje_promedio,
    COUNT(*) AS cantidad_vinos
FROM wine_reviews wr
LEFT JOIN t_country tc ON wr.id_country = tc.id_country
LEFT JOIN t_variety tv ON wr.id_variety = tv.id_variety
GROUP BY pais, variedad
HAVING COUNT(*) >= 30                                   -- minimo de 30 vinos por variedad en ese pais
ORDER BY puntaje_promedio DESC;                         -- ordena por puntaje

-- Top 3 variedades mas producidas en cada pais 
SELECT *
FROM (
    SELECT 
        tc.country_name AS pais,
        tv.variety_name AS variedad,
        COUNT(*) AS cantidad_vinos,
        ROW_NUMBER() OVER (PARTITION BY tc.country_name ORDER BY COUNT(*) DESC) AS rn     
    FROM wine_reviews wr                                              -- ranking dentro de cada país
    LEFT JOIN t_country tc ON wr.id_country = tc.id_country
    LEFT JOIN t_variety tv ON wr.id_variety = tv.id_variety
    GROUP BY pais, variedad
) AS t
WHERE rn <= 3
ORDER BY cantidad_vinos desc;

-- Distribucion de vinos por rango de precio
SELECT 
    tc.country_name AS pais,
    CASE 
        WHEN wr.price < 15 THEN 'Menos de 15'
        WHEN wr.price BETWEEN 15 AND 29 THEN '15-29'
        WHEN wr.price BETWEEN 30 AND 49 THEN '30-49'
        WHEN wr.price BETWEEN 50 AND 99 THEN '50-99'
        ELSE '100+'
    END AS rango_precio,
    COUNT(*) AS cantidad_vinos,
    ROUND(AVG(wr.points), 2) AS puntaje_promedio
FROM wine_reviews wr
LEFT JOIN t_country tc ON wr.id_country = tc.id_country
WHERE wr.price IS NOT NULL
GROUP BY pais, rango_precio
ORDER BY pais, rango_precio;

-- Ranking de paises y bodega más reseñada
-- Calcula puntaje y precio promedio por pais
WITH resumen_pais AS (
    SELECT 
        tc.country_name AS pais,
        ROUND(AVG(wr.points), 2) AS puntaje_promedio,
        ROUND(AVG(wr.price), 2) AS precio_promedio,
        COUNT(*) AS total_vinos_pais
    FROM wine_reviews wr
    LEFT JOIN t_country tc ON wr.id_country = tc.id_country
    WHERE wr.points IS NOT NULL 
      AND wr.price IS NOT NULL
    GROUP BY pais
),
-- Ranking de paises segun puntaje promedio
ranking AS (
    SELECT 
        pais,
        puntaje_promedio,
        precio_promedio,
        total_vinos_pais,
        ROW_NUMBER() OVER (ORDER BY puntaje_promedio DESC) AS ranking_pais
    FROM resumen_pais
),
-- Bodega mas reseñada por pais
bodega_top AS (
    SELECT 
        tc.country_name AS pais,
        tw.winery_name AS bodega,
        COUNT(*) AS cantidad_reseñas,
        ROW_NUMBER() OVER (
            PARTITION BY tc.country_name 
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM wine_reviews wr
    LEFT JOIN t_country tc ON wr.id_country = tc.id_country
    LEFT JOIN t_winery tw ON wr.id_winery = tw.id_winery
    GROUP BY pais, bodega
)
-- Resultado final: ranking, bodega y porcentaje
SELECT 
    r.ranking_pais,
    r.pais,
    r.puntaje_promedio,
    r.precio_promedio,
    r.total_vinos_pais,
    b.bodega AS bodega_mas_reseñada,
    b.cantidad_reseñas,
    ROUND((b.cantidad_reseñas / r.total_vinos_pais) * 100, 2) AS porcentaje_bodega
FROM ranking r
LEFT JOIN bodega_top b 
    ON r.pais = b.pais AND b.rn = 1
ORDER BY r.ranking_pais;
