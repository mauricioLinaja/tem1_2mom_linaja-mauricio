-- ============================================================================
-- UNIVERSIDAD DEL VALLE - EXAMEN PRÁCTICO INDIVIDUAL (2DO MOMENTO)
-- Archivo: sql/ddl/01_create_database_and_staging.hql
-- Autor: Mauricio Waly Linaja Canty (mlinaja)
-- Descripción: Creación de la base de datos y tabla externa de Staging
--              utilizando OpenCSVSerde para procesar correctamente los 2,221
--              registros que contienen comas dentro de comillas en Product Name.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS db_superstore_mlinaja
COMMENT 'Base de datos analitica para el proyecto Superstore Sales Dataset - Mauricio Linaja';

USE db_superstore_mlinaja;

DROP TABLE IF EXISTS superstore_staging;

CREATE EXTERNAL TABLE superstore_staging (
    row_id          STRING COMMENT 'Identificador unico de fila en el CSV',
    order_id        STRING COMMENT 'Identificador de la orden de compra',
    order_date      STRING COMMENT 'Fecha del pedido en formato original M/d/yyyy',
    ship_date       STRING COMMENT 'Fecha de envio en formato original M/d/yyyy',
    ship_mode       STRING COMMENT 'Modalidad logistica de envio',
    customer_id     STRING COMMENT 'Identificador unico del cliente',
    customer_name   STRING COMMENT 'Nombre completo del cliente',
    segment         STRING COMMENT 'Segmento del cliente (Consumer, Corporate, Home Office)',
    country         STRING COMMENT 'Pais de destino',
    city            STRING COMMENT 'Ciudad de destino',
    state           STRING COMMENT 'Estado de destino',
    postal_code     STRING COMMENT 'Codigo postal de 5 digitos',
    region          STRING COMMENT 'Region comercial (West, East, Central, South)',
    product_id      STRING COMMENT 'Identificador del producto',
    category        STRING COMMENT 'Categoria principal del producto',
    sub_category    STRING COMMENT 'Subcategoria del producto',
    product_name    STRING COMMENT 'Nombre descriptivo del producto (contiene comas internas)',
    sales           STRING COMMENT 'Monto bruto de la venta en USD',
    quantity        STRING COMMENT 'Cantidad de unidades vendidas',
    discount        STRING COMMENT 'Proporcion de descuento aplicado (0 a 1)',
    profit          STRING COMMENT 'Ganancia o perdida neta en USD'
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar'     = '"',
    'escapeChar'    = '\\'
)
STORED AS TEXTFILE
TBLPROPERTIES (
    'skip.header.line.count' = '1',
    'serialization.encoding' = 'ISO-8859-1'
);
