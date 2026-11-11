-- ============================================================================
-- BLOQUE IV COMPLEMENTARIO: OPTIMIZACIÓN Y TOMA DE DECISIONES
-- SCRIPT 09: Particionamiento Dinámico por Año y Región (Partition Pruning)
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

CREATE TABLE IF NOT EXISTS superstore_partitioned (
    row_id INT, order_id STRING, order_date DATE, ship_date DATE,
    ship_mode STRING, customer_id STRING, customer_name STRING, segment STRING,
    state STRING, city STRING, postal_code STRING, product_id STRING,
    category STRING, sub_category STRING, product_name STRING,
    sales DECIMAL(12,4), quantity INT, discount DECIMAL(5,2), profit DECIMAL(12,4)
)
PARTITIONED BY (anio_pedido INT, region STRING)
STORED AS ORC
TBLPROPERTIES ('orc.compress' = 'SNAPPY');

INSERT OVERWRITE TABLE superstore_partitioned PARTITION (anio_pedido, region)
SELECT
    row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name,
    segment, state, city, postal_code, product_id, category, sub_category, product_name,
    sales, quantity, discount, profit,
    YEAR(order_date) AS anio_pedido,
    region
FROM superstore_analytics;

SHOW PARTITIONS superstore_partitioned;
EXPLAIN SELECT category, SUM(sales), SUM(profit) FROM superstore_partitioned WHERE anio_pedido = 2017 AND region = 'West' GROUP BY category;
