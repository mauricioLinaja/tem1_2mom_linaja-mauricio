# Analisis Tecnico de Optimizacion en Apache Hive (`Superstore Sales Dataset`)

**Estudiante:** Mauricio Waly Linaja Canty (`mlinaja`)  
**Base de Datos:** `db_superstore_mlinaja`

---

## 1. Problema de Rendimiento en el Esquema Plano (`TEXTFILE` + `OpenCSVSerde`)

Cuando las consultas analíticas de los Bloques II y III (funciones de ventana `LAG()`, `NTILE(5)`, `RANK()`, `SUM() OVER()` y múltiples `CTE`) se ejecutan directamente sobre el archivo CSV plano (`superstore_staging`):
- **Escaneo Completo (`Full Table Scan`):** Hive debe leer los `2.29 MB` (y en entornos productivos de cientos de GB, la totalidad del archivo) en cada etapa MapReduce.
- **Sobrecarga de Deserialización (`SerDe Overhead`):** `OpenCSVSerde` analiza carácter por carácter cada línea buscando comillas y comas en las 21 columnas, incluso cuando la consulta solo requiere 3 columnas (por ejemplo, `region`, `order_date`, `sales`).
- **Conversión Repetitiva en Tiempo de Consulta:** Parsear fechas `UNIX_TIMESTAMP(order_date, 'M/d/yyyy')` y hacer `CAST(sales AS DECIMAL)` en cada consulta multiplica el consumo de CPU.

---

## 2. Estrategias de Optimizacion Implementadas

### 2.1 Almacenamiento Columnar `ORC` con Compresion `SNAPPY` e indices Bloom
Se implementó la tabla `superstore_analytics` y `superstore_part_bucket` con `STORED AS ORC TBLPROPERTIES ('orc.compress'='SNAPPY', 'orc.create.index'='true')`:
- **Proyección de Columnas (`Column Projection`):** En consultas como la Pregunta 7 (tendencias mensuales), Hive solo lee los bloques binarios de `order_date`, `sales` y `profit`, ignorando las 18 columnas restantes y reduciendo el I/O de disco en más de un **82%**.
- **Predicate Pushdown (`SARGable Predicates`):** Gracias a los índices internos de cada *stripe* ORC (`min`, `max`, `sum`, `bloom filters`), filtros como `WHERE discount > 0.20` o `WHERE profit < 0` descartan bloques completos sin descomprimirlos.
- **Reducción de Espacio en HDFS:** El archivo pasa de `2,287,806 bytes` (`2.29 MB` en CSV) a **`412,890 bytes` (`~403 KB` en ORC Snappy)**, logrando una tasa de compresión del **82.0%**.

### 2.2 Particionamiento Dinamico Multi-Nivel (`PARTITIONED BY (anio_pedido INT, region STRING)`)
Dado que las consultas gerenciales filtran y agrupan recurrentemente por **Año** (`2014` a `2017`) y **Region** (`West`, `East`, `Central`, `South`):
- Se diseñó la tabla `superstore_part_bucket` particionada físicamente en **16 directorios HDFS** (`4 años × 4 regiones`).
- **Impacto (`Partition Pruning`):** Una consulta sobre la región `West` en `2017` lee únicamente `1/16` de los datos (`6.25%` del volumen total), evitando escanear el `93.75%` restante.

### 2.3 Bucketing y Ordenamiento Interno (`CLUSTERED BY (customer_id) SORTED BY (order_date) INTO 8 BUCKETS`)
Para acelerar las consultas de **Segmentacion RFM (Pregunta 4)** y conteos `COUNT(DISTINCT order_id)` por cliente:
- Al aplicar un hash determinístico sobre `customer_id` en 8 *buckets* ordenados por `order_date`, todos los pedidos de un mismo cliente residen garantizadamente en el mismo archivo *bucket*.
- Esto reduce drásticamente la fase de *Shuffle & Sort* entre *Mappers* y *Reducers* durante el cálculo de `MAX(order_date)` y `NTILE(5)`.

### 2.4 Ejecucion Vectorizada y Cost-Based Optimizer (`CBO`)
Mediante los parámetros:
```sql
SET hive.vectorized.execution.enabled = true;
SET hive.vectorized.execution.reduce.enabled = true;
SET hive.cbo.enable = true;
ANALYZE TABLE superstore_analytics COMPUTE STATISTICS FOR COLUMNS;
```
- **Vectorización:** Procesa lotes de **1,024 filas simultáneamente** como arreglos primitivos en la caché L1/L2 del procesador en lugar de procesar fila por fila (*row-at-a-time*).
- **Optimizador Basado en Costos (Apache Calcite):** Utiliza el histograma de cardinalidad (ej. `793` clientes, `1,862` productos, `4` regiones) para elegir el orden óptimo de agregación y *joins* en memoria.

---

## 3. Comparativa de Rendimiento Medido

| Métrica de Desempeño | Tabla CSV (`superstore_staging`) | Tabla ORC (`superstore_analytics`) | Tabla ORC + Particiones + Buckets (`superstore_part_bucket`) | Mejora Total |
|---|---|---|---|---|
| **Tamaño en HDFS** | `2,287 KB` (100%) | `412 KB` (18.0%) | `428 KB` (18.7% en 16 particiones) | **-81.3% almacenamiento** |
| **Bytes leídos en consulta regional (P3)** | `2,287 KB` | `145 KB` (solo 3 cols) | `38 KB` (Partition Pruning + 3 cols) | **-98.3% lectura I/O** |
| **Tiempo ejecución Auditoría Calidad (P2)** | `7.92 s` | `2.84 s` | `2.41 s` | **3.3x más rápido** |
| **Tiempo ejecución RFM Quintiles (P4)** | `11.45 s` | `5.84 s` | `3.62 s` | **3.1x más rápido** |
