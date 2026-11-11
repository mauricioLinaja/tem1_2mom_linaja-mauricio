-- ============================================================================
-- BLOQUE I. INGENIERIA Y MODELADO DE DATOS
-- PREGUNTA 1: Diseño e implementación del modelo de datos en Apache Hive
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS db_superstore_mlinaja;
USE db_superstore_mlinaja;

-- 1. Tabla Externa Staging con OpenCSVSerde para campos con comas entrecomilladas
CREATE EXTERNAL TABLE IF NOT EXISTS superstore_staging (
    row_id STRING, order_id STRING, order_date STRING, ship_date STRING,
    ship_mode STRING, customer_id STRING, customer_name STRING, segment STRING,
    country STRING, city STRING, state STRING, postal_code STRING, region STRING,
    product_id STRING, category STRING, sub_category STRING, product_name STRING,
    sales STRING, quantity STRING, discount STRING, profit STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar'     = '"',
    'escapeChar'    = '\\'
)
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count' = '1', 'serialization.encoding' = 'ISO-8859-1');

-- 2. Carga del archivo CSV en Staging
LOAD DATA LOCAL INPATH '/opt/superstore.csv' OVERWRITE INTO TABLE superstore_staging;

-- 3. Tabla Analítica Tipada en formato columnar ORC
CREATE TABLE IF NOT EXISTS superstore_analytics (
    row_id          INT,
    order_id        STRING,
    order_date      DATE,
    ship_date       DATE,
    ship_mode       STRING,
    customer_id     STRING,
    customer_name   STRING,
    segment         STRING,
    country         STRING,
    city            STRING,
    state           STRING,
    postal_code     STRING,
    region          STRING,
    product_id      STRING,
    category        STRING,
    sub_category    STRING,
    product_name    STRING,
    sales           DECIMAL(12,4),
    quantity        INT,
    discount        DECIMAL(5,2),
    profit          DECIMAL(12,4)
)
STORED AS ORC
TBLPROPERTIES ('orc.compress' = 'SNAPPY');

-- 4. Transformación e Ingesta desde Staging hacia la Tabla Analítica
INSERT OVERWRITE TABLE superstore_analytics
SELECT
    CAST(TRIM(row_id) AS INT),
    TRIM(order_id),
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(TRIM(order_date), 'M/d/yyyy'))),
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(TRIM(ship_date), 'M/d/yyyy'))),
    TRIM(ship_mode),
    TRIM(customer_id),
    TRIM(customer_name),
    TRIM(segment),
    TRIM(country),
    TRIM(city),
    TRIM(state),
    TRIM(postal_code),
    TRIM(region),
    TRIM(product_id),
    TRIM(category),
    TRIM(sub_category),
    TRIM(product_name),
    CAST(TRIM(sales) AS DECIMAL(12,4)),
    CAST(TRIM(quantity) AS INT),
    CAST(TRIM(discount) AS DECIMAL(5,2)),
    CAST(TRIM(profit) AS DECIMAL(12,4))
FROM superstore_staging
WHERE row_id IS NOT NULL AND TRIM(row_id) <> 'Row ID';

-- 5. Validación de estructura y muestra de registros importados
DESCRIBE FORMATTED superstore_analytics;
SELECT COUNT(*) AS total_registros FROM superstore_analytics;
SELECT row_id, order_id, order_date, ship_date, customer_id, region, category, sales, quantity, discount, profit
FROM superstore_analytics
LIMIT 10;
