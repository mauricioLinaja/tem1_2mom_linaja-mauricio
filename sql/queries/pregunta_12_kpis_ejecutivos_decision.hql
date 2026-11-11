-- ============================================================================
-- BLOQUE IV COMPLEMENTARIO: OPTIMIZACIÓN Y TOMA DE DECISIONES
-- SCRIPT 12: Tablero de KPIs Ejecutivos por Segmento, Modalidad de Envío y SLA
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

SELECT
    segment,
    ship_mode,
    COUNT(DISTINCT order_id)                                    AS total_ordenes,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 2)              AS tiempo_envio_prom_dias,
    ROUND(SUM(sales), 2)                                        AS ventas_totales,
    ROUND(SUM(profit), 2)                                       AS ganancia_neta,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2)                  AS margen_rentabilidad_pct,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2)             AS ticket_promedio_orden
FROM superstore_analytics
GROUP BY segment, ship_mode
ORDER BY segment, ganancia_neta DESC;
