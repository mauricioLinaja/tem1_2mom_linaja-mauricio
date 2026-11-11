-- ============================================================================
-- UNIVERSIDAD DEL VALLE - EXAMEN PRÁCTICO INDIVIDUAL (2DO MOMENTO)
-- Archivo: sql/ddl/02_create_analytic_table.hql
-- Autor: Mauricio Waly Linaja Canty (mlinaja)
-- Descripción: Creación de la tabla analítica tipada en formato columnar ORC
--              con tipos exactos (DATE, DECIMAL, INT, STRING) para consultas
--              analíticas avanzadas.
-- ============================================================================

USE db_superstore_mlinaja;

DROP TABLE IF EXISTS superstore_analytics;

CREATE TABLE superstore_analytics (
    row_id          INT             COMMENT 'Identificador unico de fila (1 a 9994)',
    order_id        STRING          COMMENT 'Codigo de la orden de compra',
    order_date      DATE            COMMENT 'Fecha de pedido estandarizada (yyyy-MM-dd)',
    ship_date       DATE            COMMENT 'Fecha de envio estandarizada (yyyy-MM-dd)',
    ship_mode       STRING          COMMENT 'Modalidad de envio',
    customer_id     STRING          COMMENT 'Codigo unico del cliente',
    customer_name   STRING          COMMENT 'Nombre del cliente',
    segment         STRING          COMMENT 'Segmento comercial del cliente',
    country         STRING          COMMENT 'Pais de entrega',
    city            STRING          COMMENT 'Ciudad de entrega',
    state           STRING          COMMENT 'Estado de entrega',
    postal_code     STRING          COMMENT 'Codigo postal (STRING para preservar ceros iniciales)',
    region          STRING          COMMENT 'Region comercial (West, East, Central, South)',
    product_id      STRING          COMMENT 'Codigo unico del producto',
    category        STRING          COMMENT 'Categoria del producto',
    sub_category    STRING          COMMENT 'Subcategoria del producto',
    product_name    STRING          COMMENT 'Nombre completo del producto',
    sales           DECIMAL(12,4)   COMMENT 'Importe de venta bruta en USD',
    quantity        INT             COMMENT 'Unidades vendidas en la linea de orden',
    discount        DECIMAL(5,2)    COMMENT 'Proporcion de descuento entre 0.00 y 1.00',
    profit          DECIMAL(12,4)   COMMENT 'Ganancia o perdida neta en USD'
)
COMMENT 'Tabla analitica principal tipada para Superstore Sales Dataset'
STORED AS ORC
TBLPROPERTIES (
    'orc.compress' = 'SNAPPY',
    'orc.create.index' = 'true'
);
