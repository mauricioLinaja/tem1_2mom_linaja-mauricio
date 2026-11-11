-- ============================================================================
-- UNIVERSIDAD DEL VALLE - EXAMEN PRÁCTICO INDIVIDUAL (2DO MOMENTO)
-- Archivo: sql/dml/02_data_cleaning_treatment.hql
-- Autor: Mauricio Waly Linaja Canty (mlinaja)
-- Descripción: Creación de vista/tabla depurada aplicando los criterios de
--              tratamiento de calidad de datos definidos en la Pregunta 2
--              (eliminación de duplicados exactos de negocio y estandarización
--              de nombres de producto por Product ID).
-- ============================================================================

USE db_superstore_mlinaja;

-- Vista curada que aplica los criterios de tratamiento de inconsistencias:
-- 1. Filtra posibles registros con fechas nulas, ventas <= 0, descuentos fuera de [0,1] o ship_date < order_date.
-- 2. Deduplica registros transaccionales exactos (como el caso US-2014-150119 / FUR-CH-10002965 con Row ID 3406 y 3407).
-- 3. Homologa el nombre de producto canónico por cada product_id usando FIRST_VALUE().

CREATE OR REPLACE VIEW vw_superstore_curada AS
WITH catalogo_canonico AS (
    SELECT
        r.*,
        FIRST_VALUE(product_name) OVER (
            PARTITION BY product_id
            ORDER BY order_date DESC, row_id DESC
        ) AS product_name_canonico,
        ROW_NUMBER() OVER (
            PARTITION BY order_id, order_date, ship_date, customer_id, product_id, sales, quantity, discount, profit
            ORDER BY row_id ASC
        ) AS dup_num
    FROM superstore_analytics r
    WHERE order_date IS NOT NULL
      AND ship_date IS NOT NULL
      AND ship_date >= order_date
      AND sales > 0
      AND discount BETWEEN 0.00 AND 1.00
)
SELECT
    row_id,
    order_id,
    order_date,
    ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name_canonico AS product_name,
    sales,
    quantity,
    discount,
    profit
FROM catalogo_canonico
WHERE dup_num = 1;
