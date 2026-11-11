-- ============================================================================
-- BLOQUE II. PROCESAMIENTO Y CONSULTAS ANALÍTICAS
-- PREGUNTA 6: Análisis del impacto de los descuentos
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- 6.1 Clasificación por rangos de descuento y cálculo de métricas de rentabilidad y pérdidas
WITH clasificacion_descuentos AS (
    SELECT
        *,
        CASE
            WHEN discount = 0 THEN '1. Sin descuento (0%)'
            WHEN discount > 0 AND discount <= 0.20 THEN '2. Descuento bajo (>0% a 20%)'
            WHEN discount > 0.20 AND discount <= 0.50 THEN '3. Descuento medio (>20% a 50%)'
            WHEN discount > 0.50 THEN '4. Descuento alto (>50%)'
        END AS rango_descuento
    FROM superstore_analytics
)
SELECT
    rango_descuento,
    COUNT(*)                                                        AS total_registros,
    ROUND(AVG(discount) * 100, 2)                                   AS descuento_promedio_pct,
    ROUND(SUM(sales), 2)                                            AS ventas_totales,
    ROUND(SUM(profit), 2)                                           AS ganancia_total,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2)                      AS margen_rentabilidad_pct,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)                     AS registros_con_perdidas,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_registros_no_rentables
FROM clasificacion_descuentos
GROUP BY rango_descuento
ORDER BY rango_descuento;

-- 6.2 Categorías y subcategorías más afectadas por los descuentos comerciales
SELECT
    category,
    sub_category,
    COUNT(*)                                                        AS total_operaciones,
    ROUND(AVG(discount) * 100, 2)                                   AS descuento_promedio_pct,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)                     AS operaciones_con_perdida,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_no_rentables,
    ROUND(SUM(sales), 2)                                            AS ventas_totales,
    ROUND(SUM(profit), 2)                                           AS ganancia_neta,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2)                      AS margen_rentabilidad_pct
FROM superstore_analytics
GROUP BY category, sub_category
ORDER BY ganancia_neta ASC
LIMIT 10;
