-- ============================================================================
-- BLOQUE IV COMPLEMENTARIO: OPTIMIZACIÓN Y TOMA DE DECISIONES
-- SCRIPT 10: Bucketing (Clustered By customer_id) para optimizar Joins y RFM
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

SET hive.enforce.bucketing = true;
SET hive.optimize.bucketmapjoin = true;
SET hive.optimize.bucketmapjoin.sortedmerge = true;

CREATE TABLE IF NOT EXISTS superstore_bucketed_clientes (
    customer_id STRING,
    customer_name STRING,
    segment STRING,
    order_id STRING,
    order_date DATE,
    region STRING,
    category STRING,
    sales DECIMAL(12,4),
    profit DECIMAL(12,4)
)
CLUSTERED BY (customer_id) SORTED BY (order_date DESC) INTO 8 BUCKETS
STORED AS ORC
TBLPROPERTIES ('orc.compress' = 'SNAPPY');

INSERT OVERWRITE TABLE superstore_bucketed_clientes
SELECT customer_id, customer_name, segment, order_id, order_date, region, category, sales, profit
FROM superstore_analytics;
