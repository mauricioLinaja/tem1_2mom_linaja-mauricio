-- ============================================================================
-- BLOQUE I. INGENIERÍA Y MODELADO DE DATOS
-- PREGUNTA 2: Auditoría de calidad e integridad de datos
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- 1. Consulta Integral de Resumen de Calidad e Integridad de Datos
SELECT
    COUNT(*)                                                                AS total_registros,
    COUNT(*) - COUNT(DISTINCT row_id)                                       AS row_id_duplicados,
    COUNT(DISTINCT order_id)                                                AS ordenes_unicas,
    COUNT(DISTINCT customer_id)                                             AS clientes_unicos,
    SUM(CASE WHEN row_id IS NULL OR order_id IS NULL OR order_date IS NULL
              OR ship_date IS NULL OR ship_mode IS NULL OR customer_id IS NULL
              OR customer_name IS NULL OR segment IS NULL OR country IS NULL
              OR city IS NULL OR state IS NULL OR postal_code IS NULL
              OR region IS NULL OR product_id IS NULL OR category IS NULL
              OR sub_category IS NULL OR product_name IS NULL OR sales IS NULL
              OR quantity IS NULL OR discount IS NULL OR profit IS NULL
             THEN 1 ELSE 0 END)                                             AS registros_con_null,
    SUM(CASE WHEN order_date IS NULL OR ship_date IS NULL THEN 1 ELSE 0 END) AS fechas_invalidas,
    SUM(CASE WHEN sales <= 0 THEN 1 ELSE 0 END)                             AS ventas_menores_iguales_cero,
    SUM(CASE WHEN discount < 0 OR discount > 1 THEN 1 ELSE 0 END)           AS descuentos_fuera_intervalo,
    SUM(CASE WHEN ship_date < order_date THEN 1 ELSE 0 END)                 AS envio_anterior_a_pedido,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)                             AS registros_con_perdida
FROM superstore_analytics;

-- 2. Auditoría Semántica Adicional: Pares (order_id, product_id) repetidos en la misma orden
SELECT
    order_id,
    product_id,
    MAX(product_name) AS product_name,
    COUNT(*) AS repeticiones,
    SUM(quantity) AS cantidad_total,
    ROUND(SUM(sales), 2) AS ventas_totales
FROM superstore_analytics
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY order_id;

-- 3. Detección de duplicado transaccional exacto ignorando row_id (Caso US-2014-150119)
SELECT
    order_id, order_date, customer_id, product_id, sales, quantity, discount, profit,
    COUNT(*) AS filas_identicas,
    MIN(row_id) AS primer_row_id,
    MAX(row_id) AS segundo_row_id
FROM superstore_analytics
GROUP BY order_id, order_date, customer_id, product_id, sales, quantity, discount, profit
HAVING COUNT(*) > 1;
