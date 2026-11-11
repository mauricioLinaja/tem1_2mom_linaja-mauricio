-- ============================================================================
-- UNIVERSIDAD DEL VALLE - EXAMEN PRÁCTICO INDIVIDUAL (2DO MOMENTO)
-- Archivo: sql/ddl/03_optimization_partitioned_orc.hql
-- Autor: Mauricio Waly Linaja Canty (mlinaja)
-- Descripción: Modelo físico optimizado con Particionamiento Dinámico por
--              (anio_pedido, region), Bucketing por (customer_id) y formato ORC.
-- ============================================================================

USE db_superstore_mlinaja;

DROP TABLE IF EXISTS superstore_part_bucket;

CREATE TABLE superstore_part_bucket (
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
    product_id      STRING,
    category        STRING,
    sub_category    STRING,
    product_name    STRING,
    sales           DECIMAL(12,4),
    quantity        INT,
    discount        DECIMAL(5,2),
    profit          DECIMAL(12,4)
)
COMMENT 'Tabla optimizada mediante particionamiento por anio_pedido/region y bucketing por customer_id'
PARTITIONED BY (anio_pedido INT, region STRING)
CLUSTERED BY (customer_id) SORTED BY (order_date ASC) INTO 8 BUCKETS
STORED AS ORC
TBLPROPERTIES (
    'orc.compress' = 'SNAPPY',
    'orc.create.index' = 'true',
    'orc.bloom.filter.columns' = 'customer_id,product_id,category'
);
