-- ============================================================================
-- BLOQUE II. PROCESAMIENTO Y CONSULTAS ANALÍTICAS
-- PREGUNTA 4: Segmentación avanzada de clientes mediante RFM
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- Análisis RFM (Recency, Frequency, Monetary) con quintiles NTILE(5)
WITH fecha_referencia AS (
    SELECT MAX(order_date) AS max_fecha FROM superstore_analytics
),
rfm_metricas AS (
    SELECT
        s.customer_id,
        MAX(s.customer_name)                        AS customer_name,
        MAX(s.segment)                              AS segmento_negocio,
        MAX(s.order_date)                           AS ultima_compra,
        DATEDIFF(f.max_fecha, MAX(s.order_date))    AS recency_dias,
        COUNT(DISTINCT s.order_id)                  AS frequency_ordenes,
        ROUND(SUM(s.sales), 2)                      AS monetary_ventas,
        ROUND(SUM(s.profit), 2)                     AS ganancia_cliente
    FROM superstore_analytics s
    CROSS JOIN fecha_referencia f
    GROUP BY s.customer_id, f.max_fecha
),
rfm_puntuaciones AS (
    SELECT
        *,
        -- En Recency: menor cantidad de días desde la última compra recibe mayor puntaje (5)
        NTILE(5) OVER (ORDER BY recency_dias DESC)      AS r_score,
        -- En Frequency: mayor cantidad de órdenes únicas recibe mayor puntaje (5)
        NTILE(5) OVER (ORDER BY frequency_ordenes ASC)  AS f_score,
        -- En Monetary: mayor volumen acumulado de ventas recibe mayor puntaje (5)
        NTILE(5) OVER (ORDER BY monetary_ventas ASC)    AS m_score
    FROM rfm_metricas
),
rfm_segmentacion AS (
    SELECT
        *,
        CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_codigo,
        (r_score + f_score + m_score) AS rfm_puntaje_total,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Alto Valor (Champions)'
            WHEN f_score >= 4 AND m_score >= 3 THEN 'Clientes Recurrentes (Loyal)'
            WHEN r_score >= 3 AND m_score >= 4 THEN 'Potencial Alto Valor (Big Spenders)'
            WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'En Riesgo de Abandono (At Risk)'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Inactivos / Perdidos (Hibernating)'
            ELSE 'Clientes Regulares / Promedio'
        END AS perfil_rfm
    FROM rfm_puntuaciones
)
-- Resumen ejecutivo por segmento RFM
SELECT
    perfil_rfm,
    COUNT(*)                                                        AS total_clientes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)              AS porcentaje_clientes,
    ROUND(AVG(recency_dias), 1)                                     AS promedio_recency_dias,
    ROUND(AVG(frequency_ordenes), 2)                                AS promedio_frequency_ordenes,
    ROUND(AVG(monetary_ventas), 2)                                  AS promedio_monetary_usd,
    ROUND(SUM(monetary_ventas), 2)                                  AS ventas_totales_segmento
FROM rfm_segmentacion
GROUP BY perfil_rfm
ORDER BY ventas_totales_segmento DESC;

-- Detalle de los 15 clientes con mayor valor monetario y su clasificación RFM
WITH fecha_referencia AS (
    SELECT MAX(order_date) AS max_fecha FROM superstore_analytics
),
rfm_metricas AS (
    SELECT
        s.customer_id,
        MAX(s.customer_name) AS customer_name,
        MAX(s.order_date) AS ultima_compra,
        DATEDIFF(f.max_fecha, MAX(s.order_date)) AS recency_dias,
        COUNT(DISTINCT s.order_id) AS frequency_ordenes,
        ROUND(SUM(s.sales), 2) AS monetary_ventas
    FROM superstore_analytics s
    CROSS JOIN fecha_referencia f
    GROUP BY s.customer_id, f.max_fecha
),
rfm_puntuaciones AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_dias DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency_ordenes ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_ventas ASC) AS m_score
    FROM rfm_metricas
)
SELECT
    customer_id,
    customer_name,
    ultima_compra,
    recency_dias,
    frequency_ordenes,
    monetary_ventas,
    CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_codigo,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Alto Valor (Champions)'
        WHEN f_score >= 4 AND m_score >= 3 THEN 'Clientes Recurrentes (Loyal)'
        WHEN r_score >= 3 AND m_score >= 4 THEN 'Potencial Alto Valor (Big Spenders)'
        WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'En Riesgo de Abandono (At Risk)'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Inactivos / Perdidos (Hibernating)'
        ELSE 'Clientes Regulares / Promedio'
    END AS perfil_rfm
FROM rfm_puntuaciones
ORDER BY monetary_ventas DESC
LIMIT 15;
