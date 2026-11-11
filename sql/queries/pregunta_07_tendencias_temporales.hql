-- ============================================================================
-- BLOQUE III. ANALÍTICA AVANZADA
-- PREGUNTA 7: Análisis de tendencias temporales
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- 7.1 Evolución mensual de ventas y ganancias, variación MoM, YoY y promedio móvil de 3 meses
WITH serie_mensual AS (
    SELECT
        YEAR(order_date)                            AS anio,
        MONTH(order_date)                           AS mes,
        DATE_FORMAT(order_date, 'yyyy-MM')          AS periodo_ym,
        ROUND(SUM(sales), 2)                        AS ventas_mensuales,
        ROUND(SUM(profit), 2)                       AS ganancias_mensuales
    FROM superstore_analytics
    GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date, 'yyyy-MM')
),
tendencias_mensuales AS (
    SELECT
        anio,
        mes,
        periodo_ym,
        ventas_mensuales,
        ganancias_mensuales,
        -- Mes inmediatamente anterior (MoM)
        LAG(ventas_mensuales, 1) OVER (ORDER BY anio, mes) AS ventas_mes_anterior,
        ROUND(
            (ventas_mensuales - LAG(ventas_mensuales, 1) OVER (ORDER BY anio, mes))
            / LAG(ventas_mensuales, 1) OVER (ORDER BY anio, mes) * 100, 2
        ) AS variacion_mes_anterior_pct,
        -- Mismo mes del año anterior (YoY: desfase de 12 meses en la serie completa de 48 meses)
        LAG(ventas_mensuales, 12) OVER (ORDER BY anio, mes) AS ventas_mismo_mes_anio_ant,
        ROUND(
            (ventas_mensuales - LAG(ventas_mensuales, 12) OVER (ORDER BY anio, mes))
            / LAG(ventas_mensuales, 12) OVER (ORDER BY anio, mes) * 100, 2
        ) AS variacion_interanual_yoy_pct,
        -- Promedio móvil de 3 meses (mes actual + 2 meses previos)
        ROUND(
            AVG(ventas_mensuales) OVER (
                ORDER BY anio, mes
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 2
        ) AS promedio_movil_3m_ventas
    FROM serie_mensual
)
SELECT *
FROM tendencias_mensuales
ORDER BY anio, mes;

-- 7.2 Identificación de los 3 meses con MAYOR y los 3 meses con MENOR volumen de ventas
WITH serie_mensual AS (
    SELECT
        DATE_FORMAT(order_date, 'yyyy-MM') AS periodo_ym,
        ROUND(SUM(sales), 2)               AS ventas_mensuales,
        ROUND(SUM(profit), 2)              AS ganancias_mensuales
    FROM superstore_analytics
    GROUP BY DATE_FORMAT(order_date, 'yyyy-MM')
),
extremos AS (
    SELECT
        periodo_ym,
        ventas_mensuales,
        ganancias_mensuales,
        RANK() OVER (ORDER BY ventas_mensuales DESC) AS rnk_mayor,
        RANK() OVER (ORDER BY ventas_mensuales ASC)  AS rnk_menor
    FROM serie_mensual
)
SELECT
    CASE
        WHEN rnk_mayor <= 3 THEN CONCAT('TOP ', CAST(rnk_mayor AS STRING), ' MAYOR VOLUMEN')
        ELSE CONCAT('TOP ', CAST(rnk_menor AS STRING), ' MENOR VOLUMEN')
    END AS clasificacion_extremo,
    periodo_ym,
    ventas_mensuales,
    ganancias_mensuales
FROM extremos
WHERE rnk_mayor <= 3 OR rnk_menor <= 3
ORDER BY ventas_mensuales DESC;
