-- ============================================================================
-- UNIVERSIDAD DEL VALLE - EXAMEN PRÁCTICO INDIVIDUAL (2DO MOMENTO)
-- Archivo: sql/dml/01_load_and_transform_dml.hql
-- Autor: Mauricio Waly Linaja Canty (mlinaja)
-- Descripción: Procedimiento de carga del archivo CSV hacia Staging y
--              transformación tipada hacia la tabla analítica superstore_analytics.
-- ============================================================================

USE db_superstore_mlinaja;

-- 1. Carga del archivo CSV local hacia la tabla Staging
LOAD DATA LOCAL INPATH '/opt/superstore.csv'
OVERWRITE INTO TABLE superstore_staging;

-- 2. Ingesta con transformación de tipos y parseo de fechas M/d/yyyy -> DATE (yyyy-MM-dd)
INSERT OVERWRITE TABLE superstore_analytics
SELECT
    CAST(TRIM(row_id) AS INT)                                               AS row_id,
    TRIM(order_id)                                                          AS order_id,
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(TRIM(order_date), 'M/d/yyyy')))    AS order_date,
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(TRIM(ship_date), 'M/d/yyyy')))     AS ship_date,
    TRIM(ship_mode)                                                         AS ship_mode,
    TRIM(customer_id)                                                       AS customer_id,
    TRIM(customer_name)                                                     AS customer_name,
    TRIM(segment)                                                           AS segment,
    TRIM(country)                                                           AS country,
    TRIM(city)                                                              AS city,
    TRIM(state)                                                             AS state,
    TRIM(postal_code)                                                       AS postal_code,
    TRIM(region)                                                            AS region,
    TRIM(product_id)                                                        AS product_id,
    TRIM(category)                                                          AS category,
    TRIM(sub_category)                                                      AS sub_category,
    TRIM(product_name)                                                      AS product_name,
    CAST(TRIM(sales) AS DECIMAL(12,4))                                      AS sales,
    CAST(TRIM(quantity) AS INT)                                             AS quantity,
    CAST(TRIM(discount) AS DECIMAL(5,2))                                    AS discount,
    CAST(TRIM(profit) AS DECIMAL(12,4))                                     AS profit
FROM superstore_staging
WHERE row_id IS NOT NULL
  AND TRIM(row_id) <> 'Row ID';

-- 3. Verificación inmediata de registros importados
SELECT COUNT(*) AS total_registros_importados FROM superstore_analytics;
SELECT * FROM superstore_analytics LIMIT 10;
