-- ============================================================================
-- BLOQUE II. PROCESAMIENTO Y CONSULTAS ANALÍTICAS
-- PREGUNTA 3: Análisis de evolución comercial por región
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- Parte A: Evolución anual de ventas, ganancias, margen y variación YoY por región usando CTE y LAG()
WITH ventas_region_anio AS (
    SELECT
        region,
        YEAR(order_date)                            AS anio,
        ROUND(SUM(sales), 2)                        AS ventas_totales,
        ROUND(SUM(profit), 2)                       AS ganancia_total,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2)  AS margen_rentabilidad_pct
    FROM superstore_analytics
    GROUP BY region, YEAR(order_date)
),
evolucion_interanual AS (
    SELECT
        region,
        anio,
        ventas_totales,
        ganancia_total,
        margen_rentabilidad_pct,
        LAG(ventas_totales, 1) OVER (PARTITION BY region ORDER BY anio) AS ventas_anio_anterior,
        ROUND(
            (ventas_totales - LAG(ventas_totales, 1) OVER (PARTITION BY region ORDER BY anio))
            / LAG(ventas_totales, 1) OVER (PARTITION BY region ORDER BY anio) * 100, 2
        ) AS variacion_ventas_pct,
        LAG(ganancia_total, 1) OVER (PARTITION BY region ORDER BY anio) AS ganancia_anio_anterior,
        ROUND(
            (ganancia_total - LAG(ganancia_total, 1) OVER (PARTITION BY region ORDER BY anio))
            / ABS(LAG(ganancia_total, 1) OVER (PARTITION BY region ORDER BY anio)) * 100, 2
        ) AS variacion_ganancia_pct
    FROM ventas_region_anio
)
SELECT *
FROM evolucion_interanual
ORDER BY region, anio;

-- Parte B: Identificación de la región con mejor y peor desempeño comercial acumulado
WITH resumen_regional AS (
    SELECT
        region,
        COUNT(DISTINCT order_id)                    AS total_ordenes,
        ROUND(SUM(sales), 2)                        AS ventas_acumuladas,
        ROUND(SUM(profit), 2)                       AS ganancia_acumulada,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2)  AS margen_global_pct
    FROM superstore_analytics
    GROUP BY region
)
SELECT
    region,
    total_ordenes,
    ventas_acumuladas,
    ganancia_acumulada,
    margen_global_pct,
    RANK() OVER (ORDER BY ganancia_acumulada DESC) AS ranking_rentabilidad,
    CASE
        WHEN RANK() OVER (ORDER BY ganancia_acumulada DESC) = 1 THEN 'MEJOR DESEMPENO COMERCIAL'
        WHEN RANK() OVER (ORDER BY ganancia_acumulada ASC)  = 1 THEN 'PEOR DESEMPENO EN RENTABILIDAD'
        ELSE 'DESEMPENO INTERMEDIO'
    END AS clasificacion_desempeno
FROM resumen_regional
ORDER BY ganancia_acumulada DESC;
