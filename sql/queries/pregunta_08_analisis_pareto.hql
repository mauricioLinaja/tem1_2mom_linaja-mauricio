-- ============================================================================
-- BLOQUE III. ANALÍTICA AVANZADA
-- PREGUNTA 8: Análisis Pareto (80/20) de ventas y rentabilidad
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- ============================================================================
-- ANÁLISIS 8.A: Regla 80/20 sobre VENTAS ACUMULADAS por producto
-- ============================================================================
WITH ventas_por_producto AS (
    SELECT
        product_id,
        MAX(product_name)       AS product_name,
        MAX(category)           AS category,
        ROUND(SUM(sales), 2)    AS ventas_producto
    FROM superstore_analytics
    GROUP BY product_id
),
pareto_ventas AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY ventas_producto DESC) AS orden_contribucion,
        product_id,
        product_name,
        category,
        ventas_producto,
        ROUND(SUM(ventas_producto) OVER (), 2) AS ventas_totales_empresa,
        ROUND(ventas_producto * 100.0 / SUM(ventas_producto) OVER (), 4) AS participacion_individual_pct,
        ROUND(
            SUM(ventas_producto) OVER (
                ORDER BY ventas_producto DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 2
        ) AS ventas_acumuladas,
        ROUND(
            SUM(ventas_producto) OVER (
                ORDER BY ventas_producto DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0 / SUM(ventas_producto) OVER (), 2
        ) AS porcentaje_acumulado,
        COUNT(*) OVER () AS total_productos_catalogo
    FROM ventas_por_producto
)
SELECT
    orden_contribucion,
    product_id,
    product_name,
    category,
    ventas_producto,
    participacion_individual_pct,
    ventas_acumuladas,
    porcentaje_acumulado,
    CASE WHEN porcentaje_acumulado <= 80.0 THEN 'CLASE A (80% Ventas)' ELSE 'CLASE B/C (20% Restante)' END AS segmento_pareto
FROM pareto_ventas
ORDER BY orden_contribucion
LIMIT 20;

-- Resumen de concentración Pareto 8.A (Cantidad exacta de productos que concentran el 80% de las ventas)
WITH ventas_por_producto AS (
    SELECT product_id, ROUND(SUM(sales), 2) AS ventas_producto
    FROM superstore_analytics GROUP BY product_id
),
pareto_ventas AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY ventas_producto DESC) AS rnk,
        SUM(ventas_producto) OVER (ORDER BY ventas_producto DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        * 100.0 / SUM(ventas_producto) OVER () AS pct_acum,
        COUNT(*) OVER () AS total_catalogo
    FROM ventas_por_producto
)
SELECT
    MIN(CASE WHEN pct_acum >= 80.0 THEN rnk END) AS productos_80pct_ventas,
    MAX(total_catalogo) AS total_productos_catalogo,
    ROUND(MIN(CASE WHEN pct_acum >= 80.0 THEN rnk END) * 100.0 / MAX(total_catalogo), 2) AS porcentaje_del_catalogo
FROM pareto_ventas;

-- ============================================================================
-- ANÁLISIS 8.B: Regla 80/20 sobre GANANCIAS ACUMULADAS por producto
-- (Se evalúa sobre el universo de productos rentables profit > 0 y sobre la ganancia neta global)
-- ============================================================================
WITH ganancias_por_producto AS (
    SELECT
        product_id,
        MAX(product_name)       AS product_name,
        MAX(category)           AS category,
        ROUND(SUM(profit), 2)   AS ganancia_producto
    FROM superstore_analytics
    GROUP BY product_id
    HAVING SUM(profit) > 0
),
pareto_ganancias AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY ganancia_producto DESC) AS orden_contribucion,
        product_id,
        product_name,
        category,
        ganancia_producto,
        ROUND(SUM(ganancia_producto) OVER (), 2) AS ganancia_positiva_total,
        ROUND(ganancia_producto * 100.0 / SUM(ganancia_producto) OVER (), 4) AS participacion_individual_pct,
        ROUND(
            SUM(ganancia_producto) OVER (
                ORDER BY ganancia_producto DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 2
        ) AS ganancia_acumulada,
        ROUND(
            SUM(ganancia_producto) OVER (
                ORDER BY ganancia_producto DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0 / SUM(ganancia_producto) OVER (), 2
        ) AS porcentaje_acumulado
    FROM ganancias_por_producto
)
SELECT
    orden_contribucion,
    product_id,
    product_name,
    category,
    ganancia_producto,
    participacion_individual_pct,
    ganancia_acumulada,
    porcentaje_acumulado,
    CASE WHEN porcentaje_acumulado <= 80.0 THEN 'CLASE A (80% Ganancias)' ELSE 'CLASE B/C (20% Restante)' END AS segmento_pareto
FROM pareto_ganancias
ORDER BY orden_contribucion
LIMIT 20;
