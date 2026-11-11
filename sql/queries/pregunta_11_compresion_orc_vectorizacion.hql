-- ============================================================================
-- BLOQUE IV COMPLEMENTARIO: OPTIMIZACIÓN Y TOMA DE DECISIONES
-- SCRIPT 11: Vectorización, Cost-Based Optimizer (CBO) e Índices Bloom en ORC
-- Estudiante: Mauricio Waly Linaja Canty (mlinaja)
-- ============================================================================

USE db_superstore_mlinaja;

-- Activación de ejecución vectorizada (procesa bloques de 1,024 filas en memoria CPU)
SET hive.vectorized.execution.enabled = true;
SET hive.vectorized.execution.reduce.enabled = true;

-- Activación del optimizador basado en costos (Apache Calcite CBO)
SET hive.cbo.enable = true;
SET hive.compute.query.using.stats = true;
SET hive.stats.fetch.column.stats = true;
SET hive.stats.fetch.partition.stats = true;

-- Recolección de estadísticas de tabla y columnas para el optimizador CBO
ANALYZE TABLE superstore_analytics COMPUTE STATISTICS;
ANALYZE TABLE superstore_analytics COMPUTE STATISTICS FOR COLUMNS
    region, category, sub_category, customer_id, product_id, sales, discount, profit;

EXPLAIN VECTORIZATION
SELECT category, sub_category, COUNT(*), SUM(sales), SUM(profit)
FROM superstore_analytics
WHERE discount > 0.20
GROUP BY category, sub_category;
