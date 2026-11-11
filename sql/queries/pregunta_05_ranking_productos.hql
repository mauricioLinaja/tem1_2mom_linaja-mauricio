-- ============================================================================
-- BLOQUE II. PROCESAMIENTO Y CONSULTAS ANALÍTICAS
-- PREGUNTA 5: Ranking de productos según rentabilidad
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- 5.1 Los cinco productos con mayor ganancia acumulada por categoría, margen individual,
--     posición dentro de su categoría (RANK y DENSE_RANK) y ganancia acumulativa (SUM OVER)
WITH metricas_producto AS (
    SELECT
        category,
        product_id,
        MAX(product_name)                           AS product_name,
        SUM(quantity)                               AS unidades_vendidas,
        ROUND(SUM(sales), 2)                        AS ventas_totales,
        ROUND(SUM(profit), 2)                       AS ganancia_acumulada,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2)  AS margen_ganancia_pct
    FROM superstore_analytics
    GROUP BY category, product_id
),
ranking_por_categoria AS (
    SELECT
        category,
        product_id,
        product_name,
        unidades_vendidas,
        ventas_totales,
        ganancia_acumulada,
        margen_ganancia_pct,
        RANK() OVER (PARTITION BY category ORDER BY ganancia_acumulada DESC)       AS posicion_rank,
        DENSE_RANK() OVER (PARTITION BY category ORDER BY ganancia_acumulada DESC) AS posicion_dense_rank,
        ROUND(
            SUM(ganancia_acumulada) OVER (
                PARTITION BY category
                ORDER BY ganancia_acumulada DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 2
        ) AS ganancia_acumulativa_categoria
    FROM metricas_producto
)
SELECT *
FROM ranking_por_categoria
WHERE posicion_rank <= 5
ORDER BY category, posicion_rank;

-- 5.2 Los cinco productos con mayor volumen de ventas globales
WITH metricas_producto AS (
    SELECT
        category,
        product_id,
        MAX(product_name)                           AS product_name,
        SUM(quantity)                               AS unidades_vendidas,
        ROUND(SUM(sales), 2)                        AS ventas_totales,
        ROUND(SUM(profit), 2)                       AS ganancia_acumulada,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2)  AS margen_ganancia_pct
    FROM superstore_analytics
    GROUP BY category, product_id
)
SELECT
    category,
    product_id,
    product_name,
    unidades_vendidas,
    ventas_totales,
    ganancia_acumulada,
    margen_ganancia_pct,
    RANK() OVER (ORDER BY ventas_totales DESC)       AS rank_ventas,
    DENSE_RANK() OVER (ORDER BY ventas_totales DESC) AS dense_rank_ventas,
    ROUND(SUM(ventas_totales) OVER (ORDER BY ventas_totales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS ventas_acumulativas
FROM metricas_producto
ORDER BY rank_ventas
LIMIT 5;

-- 5.3 Los cinco productos con menor rentabilidad (mayores pérdidas acumuladas)
WITH metricas_producto AS (
    SELECT
        category,
        product_id,
        MAX(product_name)                           AS product_name,
        SUM(quantity)                               AS unidades_vendidas,
        ROUND(SUM(sales), 2)                        AS ventas_totales,
        ROUND(SUM(profit), 2)                       AS ganancia_acumulada,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2)  AS margen_ganancia_pct
    FROM superstore_analytics
    GROUP BY category, product_id
)
SELECT
    category,
    product_id,
    product_name,
    unidades_vendidas,
    ventas_totales,
    ganancia_acumulada,
    margen_ganancia_pct,
    RANK() OVER (ORDER BY ganancia_acumulada ASC)       AS rank_menor_rentabilidad,
    DENSE_RANK() OVER (ORDER BY ganancia_acumulada ASC) AS dense_rank_menor_rentabilidad,
    ROUND(SUM(ganancia_acumulada) OVER (ORDER BY ganancia_acumulada ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS perdida_acumulativa
FROM metricas_producto
ORDER BY rank_menor_rentabilidad
LIMIT 5;
