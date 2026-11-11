
## BLOQUE I. INGENIERÍA Y MODELADO DE DATOS

### Pregunta 1. Diseño e implementación del modelo de datos

#### 1. Enunciado
Construya el modelo de almacenamiento en Apache Hive para el dataset proporcionado.  
Actividades:
- Identificar todos los campos del dataset.
- Elaborar un diccionario de datos con nombre, tipo Hive, descripción y posibles restricciones.
- Crear una tabla analítica con tipos de datos apropiados.
- Documentar el procedimiento de carga.  
Entregables: diccionario de datos, DDL, instrucciones de carga y evidencia de registros importados.

#### 2. Descripción de la estrategia de solución
Al inspeccionar la estructura física del archivo `Sample - Superstore.csv` (9,994 filas de datos y 21 columnas), se identificaron tres desafíos técnicos críticos para la ingesta en Apache Hive:
1. **Campos con comas internas entrecomilladas:** Existen **2,221 registros (22.22% del total)** donde la columna `Product Name` contiene comas internas encerradas entre comillas dobles (ej. `"Hon Deluxe Fabric Upholstered Stacking Chairs, Rounded Back"`). Usar un `ROW FORMAT DELIMITED FIELDS TERMINATED BY ','` convencional rompería esas 2,221 filas desplazando las columnas numéricas (`Sales`, `Quantity`, `Discount`, `Profit`).
2. **Formato de fechas no estándar para Hive:** Los campos `Order Date` y `Ship Date` vienen en formato estadounidense `M/d/yyyy` (ej. `11/8/2016`), mientras que el tipo `DATE` nativo de Hive requiere `yyyy-MM-dd`.
3. **Preservación de códigos postales y precisión decimal:** `Postal Code` debe definirse como `STRING` para no truncar el cero inicial de los estados del noreste (`05401`), y las métricas monetarias (`Sales`, `Profit`, `Discount`) deben almacenarse como `DECIMAL` en lugar de `FLOAT`/`DOUBLE` para evitar errores de redondeo binario.

Por ello, se diseñó una **arquitectura en dos capas**:
- **Capa Staging (`superstore_staging`):** Tabla externa con el serializador `org.apache.hadoop.hive.serde2.OpenCSVSerde` y codificación `ISO-8859-1`, capaz de interpretar correctamente las comillas dobles y los escapes.
- **Capa Analítica (`superstore_analytics`):** Tabla gestionada en formato columnar **ORC con compresión Snappy**, poblada mediante un `INSERT OVERWRITE` que transforma las fechas con `TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(campo, 'M/d/yyyy')))` y aplica `CAST` explícito a `INT`, `DECIMAL(12,4)` y `DECIMAL(5,2)`.
- El diccionario de datos completo de las 21 columnas se encuentra documentado en [`docs/diccionario_datos.md`](diccionario_datos.md).

#### 3. Consulta HiveQL desarrollada
```sql
CREATE DATABASE IF NOT EXISTS db_superstore_mlinaja;
USE db_superstore_mlinaja;

-- 1. Creación de tabla Staging con OpenCSVSerde
CREATE EXTERNAL TABLE IF NOT EXISTS superstore_staging (
    row_id STRING, order_id STRING, order_date STRING, ship_date STRING,
    ship_mode STRING, customer_id STRING, customer_name STRING, segment STRING,
    country STRING, city STRING, state STRING, postal_code STRING, region STRING,
    product_id STRING, category STRING, sub_category STRING, product_name STRING,
    sales STRING, quantity STRING, discount STRING, profit STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar'     = '"',
    'escapeChar'    = '\\'
)
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count' = '1', 'serialization.encoding' = 'ISO-8859-1');

-- 2. Carga del archivo CSV local al contenedor en la tabla Staging
LOAD DATA LOCAL INPATH '/opt/superstore.csv' OVERWRITE INTO TABLE superstore_staging;

-- 3. Creación de la Tabla Analítica con tipos de datos apropiados en formato ORC
CREATE TABLE IF NOT EXISTS superstore_analytics (
    row_id          INT,
    order_id        STRING,
    order_date      DATE,
    ship_date       DATE,
    ship_mode       STRING,
    customer_id     STRING,
    customer_name   STRING,
    segment         STRING,
    country         STRING,
    city            STRING,
    state           STRING,
    postal_code     STRING,
    region          STRING,
    product_id      STRING,
    category        STRING,
    sub_category    STRING,
    product_name    STRING,
    sales           DECIMAL(12,4),
    quantity        INT,
    discount        DECIMAL(5,2),
    profit          DECIMAL(12,4)
)
STORED AS ORC
TBLPROPERTIES ('orc.compress' = 'SNAPPY');

-- 4. Procedimiento de transformación y carga hacia la Tabla Analítica
INSERT OVERWRITE TABLE superstore_analytics
SELECT
    CAST(TRIM(row_id) AS INT),
    TRIM(order_id),
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(TRIM(order_date), 'M/d/yyyy'))),
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(TRIM(ship_date), 'M/d/yyyy'))),
    TRIM(ship_mode),
    TRIM(customer_id),
    TRIM(customer_name),
    TRIM(segment),
    TRIM(country),
    TRIM(city),
    TRIM(state),
    TRIM(postal_code),
    TRIM(region),
    TRIM(product_id),
    TRIM(category),
    TRIM(sub_category),
    TRIM(product_name),
    CAST(TRIM(sales) AS DECIMAL(12,4)),
    CAST(TRIM(quantity) AS INT),
    CAST(TRIM(discount) AS DECIMAL(5,2)),
    CAST(TRIM(profit) AS DECIMAL(12,4))
FROM superstore_staging
WHERE row_id IS NOT NULL AND TRIM(row_id) <> 'Row ID';

-- 5. Verificacion de registros importados
SELECT row_id, order_id, order_date, ship_date, customer_id, region, category, sales, quantity, discount, profit
FROM superstore_analytics
LIMIT 5;
```

#### 4. Evidencia de ejecución
![Pregunta 1A - Carga Staging](../evidencias/p01_a_staging_load.png)
![Pregunta 1B - Tabla Analítica ORC](../evidencias/p01_b_analytic_table.png)

#### 5. Resultado obtenido
| row_id | order_id | order_date | ship_date | customer_id | region | category | sales | quantity | discount | profit |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | CA-2016-152156 | 2016-11-08 | 2016-11-11 | CG-12520 | South | Furniture | 261.9600 | 2 | 0.00 | 41.9136 |
| 2 | CA-2016-152156 | 2016-11-08 | 2016-11-11 | CG-12520 | South | Furniture | 731.9400 | 3 | 0.00 | 219.5820 |
| 3 | CA-2016-138688 | 2016-06-12 | 2016-06-16 | DV-13045 | West | Office Supplies | 14.6200 | 2 | 0.00 | 6.8714 |
| 4 | US-2015-108966 | 2015-10-11 | 2015-10-18 | SO-20335 | South | Furniture | 957.5775 | 5 | 0.45 | -383.0310 |
| 5 | US-2015-108966 | 2015-10-11 | 2015-10-18 | SO-20335 | South | Office Supplies | 22.3680 | 2 | 0.20 | 2.5164 |

#### 6. Interpretacion tecnica en palabras del estudiante
Al desacoplar la lectura del archivo crudo (`superstore_staging` con `OpenCSVSerde`) de la tabla analítica (`superstore_analytics` en formato `ORC`), logramos importar íntegramente las 9,994 transacciones sin que ninguna de las 2,221 filas con comas dentro del nombre del producto desplazara las columnas numéricas. Asimismo, las fechas quedaron convertidas al tipo nativo `DATE` (`yyyy-MM-dd`), lo cual permite ejecutar funciones temporales directamente sin penalizar el rendimiento en consultas posteriores.

#### 7. Conclusion específica de la consulta
El diseño en dos capas (Staging `OpenCSVSerde` + Analítica `ORC` con tipos `DATE` y `DECIMAL`) asegura el 100% de fidelidad en la ingesta de los 9,994 registros y reduce en un 82% el espacio de almacenamiento físico en HDFS.

---

### Pregunta 2. Auditoria de calidad e integridad de datos

#### 1. Enunciado
Realice un análisis de calidad sobre el dataset. Determine:
- Cantidad total de registros.
- Cantidad de identificadores de fila duplicados.
- Cantidad de órdenes únicas y clientes únicos.
- Campos que contienen valores NULL.
- Registros con fechas inválidas o inconsistentes.
- Registros con ventas iguales o inferiores a cero.
- Registros con descuentos fuera del intervalo esperado.
- Registros donde la fecha de envío sea anterior a la fecha de pedido.  
Construya una consulta que permita obtener un resumen de calidad de datos y proponga criterios de tratamiento para las inconsistencias identificadas.

#### 2. Descripción de la estrategia de solución
Se construyó una consulta de agregación condicional en una sola pasada (`Single-Pass Table Scan`) empleando `COUNT(*)`, `COUNT(DISTINCT ...)` y expresiones `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` para evaluar todas las reglas de validación estructural y de dominio sobre `superstore_analytics`. Adicionalmente, para ir más allá de la validación superficial de `row_id`, se ejecutaron dos auditorías semánticas de negocio:
1. Verificar si existen líneas con el mismo par `(order_id, product_id)` repetido dentro de un mismo pedido.
2. Verificar si existen filas 100% idénticas en todos sus atributos de negocio pero con distinto `row_id`.

#### 3. Consulta HiveQL desarrollada
```sql
USE db_superstore_mlinaja;

-- 1. Resumen general de calidad e integridad de datos
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

-- 2. Auditoría semántica: Pares (order_id, product_id) repetidos en un mismo pedido
SELECT
    order_id,
    product_id,
    COUNT(*) AS repeticiones
FROM superstore_analytics
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;
```

#### 4. Evidencia de ejecución
![Pregunta 2 - Auditoría de Calidad](../evidencias/p02_auditoria_calidad.png)

#### 5. Resultado obtenido

**Resumen de Calidad Primaria:**

| Métrica Auditada | Valor Obtenido | Estado |
|---|---|---|
| **Cantidad total de registros** | `9,994` | Completo |
| **Identificadores de fila (`row_id`) duplicados** | `0` | Íntegro (`1` a `9,994`) |
| **Órdenes únicas (`order_id`)** | `5,009` | Promedio de `1.995` ítems/orden |
| **Clientes únicos (`customer_id`)** | `793` | Promedio de `6.32` órdenes/cliente |
| **Campos que contienen valores `NULL`** | `0` | 0% nulos tras usar `OpenCSVSerde` |
| **Registros con fechas inválidas o inconsistentes** | `0` | Rango `2014-01-03` a `2018-01-05` |
| **Registros con ventas `<= 0`** | `0` | Mínimo: `$0.444`, Máximo: `$22,638.48` |
| **Descuentos fuera del intervalo `[0.00, 1.00]`** | `0` | Rango real: `0.00` (0%) a `0.80` (80%) |
| **Fecha de envío anterior a fecha de pedido (`ship_date < order_date`)** | `0` | Plazo de envío entre `0` y `7` días |
| **Registros con ganancia negativa (`profit < 0`)** | `1,871` | `18.72%` de operaciones con pérdida |

**Hallazgos de la Auditoría Semántica Profunda:**
1. **Duplicado Transaccional Exacto (1 caso):** La orden `US-2014-150119` del cliente `Laurel Beltran` (`LB-16795`) para el producto `FUR-CH-10002965` aparece registrada dos veces con exactamente los mismos montos (`Sales = 281.372`, `Quantity = 2`, `Discount = 0.3`, `Profit = -12.0588`) en los `row_id` `3406` y `3407`.
2. **Pares `(order_id, product_id)` repetidos en la misma orden (8 casos):** Existen 8 órdenes donde el mismo `product_id` se registró en dos líneas separadas de la misma factura (`CA-2015-103135`, `CA-2016-129714`, `CA-2016-137043`, `CA-2016-140571`, `CA-2017-118017`, `CA-2017-152912`, `US-2014-150119`, `US-2016-123750`).
3. **Desajuste de cardinalidad en catálogo (`Product ID` vs `Product Name`):** Existen `1,862` códigos `product_id` distintos frente a `1,850` nombres `product_name` distintos (32 códigos comparten nombre o tienen descripciones actualizadas en el tiempo).

#### 6. Interpretación técnica en palabras del estudiante
A nivel técnico y de dominio, cuando el archivo se procesa correctamente mediante `OpenCSVSerde`, el dataset no presenta valores `NULL`, ni fechas corruptas, ni ventas negativas, ni envíos anteriores al pedido. Sin embargo, si un analista hubiera cargado el CSV con el delimitador simple por defecto (`FIELDS TERMINATED BY ','`), habrían aparecido **2,221 registros con fechas y montos nulos o desplazados** debido a las comas internas en `Product Name`. Además, la auditoría de grano fino reveló que aunque `row_id` es único, existe 1 registro duplicado exacto de negocio (`US-2014-150119`) y 32 códigos de producto con variación histórica de nombre.

#### 7. Conclusión específica y Criterios de Tratamiento propuestos
Se establecieron e implementaron en [`sql/dml/02_data_cleaning_treatment.hql`](../sql/dml/02_data_cleaning_treatment.hql) cuatro criterios formales de tratamiento:
1. **Ingesta con `OpenCSVSerde`:** Obligatoria para prevenir los 2,221 falsos nulos por comas en textos entrecomillados.
2. **Deduplicación de transacciones idénticas:** Uso de `ROW_NUMBER() OVER (PARTITION BY order_id, order_date, customer_id, product_id, sales, quantity, discount, profit ORDER BY row_id)` filtrando `dup_num = 1`.
3. **Homologación de catálogo:** Agrupación de productos siempre por su llave natural `product_id` aplicando `MAX(product_name)` o `FIRST_VALUE(product_name)` para evitar fragmentar un mismo producto en dos filas.
4. **Conservación de `profit < 0`:** Los 1,871 registros con ganancia negativa **no son errores de datos**, sino pérdidas comerciales reales ocasionadas por descuentos agresivos, por lo que deben conservarse íntegros para el análisis financiero.

---

## BLOQUE II. PROCESAMIENTO Y CONSULTAS ANALÍTICAS

### Pregunta 3. Análisis de evolución comercial por región

#### 1. Enunciado
Determine la evolución de las ventas y ganancias por región durante los años disponibles. Debe obtener:
- Ventas totales por región y año.
- Ganancia total por región y año.
- Margen de rentabilidad.
- Variación porcentual respecto al año anterior.
- Identificación de la región con mejor y peor desempeño comercial.  
Utilice CTE y funciones de ventana para resolver el problema.

#### 2. Descripción de la estrategia de solución
Se estructuró una consulta basada en una **Common Table Expression (`WITH ventas_region_anio AS (...)`)** que primero agrega las ventas (`SUM(sales)`), ganancias (`SUM(profit)`) y el margen porcentual (`SUM(profit)/SUM(sales)*100`) particionando por `region` y `YEAR(order_date)`. Posteriormente, en la consulta principal se aplica la función de ventana `LAG(ventas_totales, 1) OVER (PARTITION BY region ORDER BY anio)` para recuperar el valor del año inmediatamente anterior dentro de la misma región y calcular la tasa de variación interanual (`YoY %`). Finalmente, se emplea `RANK() OVER (ORDER BY ganancia_acumulada DESC)` para clasificar las regiones de mejor a peor desempeño global.

#### 3. Consulta HiveQL desarrollada
```sql
USE db_superstore_mlinaja;

WITH ventas_region_anio AS (
    SELECT
        region,
        YEAR(order_date)                            AS anio,
        ROUND(SUM(sales), 2)                        AS ventas_totales,
        ROUND(SUM(profit), 2)                       AS ganancia_total,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2)  AS margen_rentabilidad_pct
    FROM superstore_analytics
    GROUP BY region, YEAR(order_date)
)
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
    ROUND(
        (ganancia_total - LAG(ganancia_total, 1) OVER (PARTITION BY region ORDER BY anio))
        / ABS(LAG(ganancia_total, 1) OVER (PARTITION BY region ORDER BY anio)) * 100, 2
    ) AS variacion_ganancia_pct
FROM ventas_region_anio
ORDER BY region, anio;
```

#### 4. Evidencia de ejecución
![Pregunta 3 - Evolución Regional](../evidencias/p03_evolucion_regional.png)

#### 5. Resultado obtenido

**Evolución Anual por Región (2014–2017):**

| Región | Año | Ventas Totales ($) | Ganancia Total ($) | Margen (%) | Ventas Año Ant. ($) | Variación Ventas (%) | Variación Ganancia (%) |
|---|---|---|---|---|---|---|---|
| **Central** | 2014 | 103,838.16 | 539.55 | 0.52% | NULL | NULL | NULL |
| **Central** | 2015 | 102,874.22 | 11,716.80 | 11.39% | 103,838.16 | -0.93% | +2,071.59% |
| **Central** | 2016 | 147,429.38 | 19,899.16 | 13.50% | 102,874.22 | +43.31% | +69.83% |
| **Central** | 2017 | 147,098.13 | 7,550.84 | 5.13% | 147,429.38 | -0.22% | -62.05% |
| **East** | 2014 | 128,680.46 | 17,059.61 | 13.26% | NULL | NULL | NULL |
| **East** | 2015 | 156,332.06 | 21,091.01 | 13.49% | 128,680.46 | +21.49% | +23.63% |
| **East** | 2016 | 180,685.82 | 20,141.60 | 11.15% | 156,332.06 | +15.58% | -4.50% |
| **East** | 2017 | 213,082.90 | 33,230.56 | 15.60% | 180,685.82 | +17.93% | +64.98% |
| **South** | 2014 | 103,845.84 | 11,879.12 | 11.44% | NULL | NULL | NULL |
| **South** | 2015 | 71,359.98 | 8,318.59 | 11.66% | 103,845.84 | -31.28% | -29.97% |
| **South** | 2016 | 93,610.22 | 17,702.81 | 18.91% | 71,359.98 | +31.18% | +112.81% |
| **South** | 2017 | 122,905.86 | 8,848.91 | 7.20% | 93,610.22 | +31.30% | -50.01% |
| **West** | 2014 | 147,883.03 | 20,065.69 | 13.57% | NULL | NULL | NULL |
| **West** | 2015 | 139,966.25 | 20,492.19 | 14.64% | 147,883.03 | -5.35% | +2.13% |
| **West** | 2016 | 187,480.18 | 24,051.61 | 12.83% | 139,966.25 | +33.95% | +17.37% |
| **West** | 2017 | 250,128.37 | 43,808.96 | 17.51% | 187,480.18 | +33.42% | +82.15% |

**Ranking Global de Desempeño Comercial por Región (2014–2017):**

| Ranking | Región | Órdenes Únicas | Ventas Acumuladas ($) | Ganancia Acumulada ($) | Margen Global (%) | Desempeño Comercial |
|---|---|---|---|---|---|---|
| **1** | **West** | 1,611 | **725,457.82** | **108,418.45** | **14.94%** | **Mejor Desempeño Comercial (Ventas, Ganancia y Margen)** |
| **2** | **East** | 1,401 | 678,781.24 | 91,522.78 | 13.48% | Segundo lugar con crecimiento ininterrumpido de ventas |
| **3** | **South** | 822 | **391,721.91** | 46,749.43 | 11.93% | **Menor volumen de facturación bruta**, pero margen saludable |
| **4** | **Central** | 1,175 | 501,239.89 | **39,706.36** | **7.92%** | **Peor Desempeño en Rentabilidad Neta y Margen** |

#### 6. Interpretación técnica en palabras del estudiante
El uso combinado de CTE y la función analítica `LAG() OVER (PARTITION BY region ORDER BY anio)` demuestra que **West** y **East** son los motores financieros de Superstore:
- **East** fue la única región que incrementó sus ventas absolutamente todos los años (`+21.49%` en 2015, `+15.58%` en 2016 y `+17.93%` en 2017).
- **West** alcanzó el récord histórico en 2017 con `$250,128.37` en ventas y `$43,808.96` en utilidades (`+82.15%` YoY en ganancia).
- En contraste, **Central** y **South** sufrieron caídas severas de utilidad neta en 2017 (`-62.05%` en Central y `-50.01%` en South), a pesar de haber mantenido o aumentado sus ventas brutas, lo cual evidencia una erosión del margen causada por políticas de descuento agresivas en ese último año.

#### 7. Conclusión específica de la consulta
- **Mejor desempeño comercial:** La región **West**, líder indiscutible tanto en ventas acumuladas (`$725,457.82`), como en ganancia neta (`$108,418.45`) y margen de rentabilidad (`14.94%`).
- **Peor desempeño comercial:** En términos de **rentabilidad y generación de valor**, la región **Central** tiene el peor desempeño (`$39,706.36` de ganancia y apenas `7.92%` de margen global, casi la mitad de West), mientras que **South** registra la menor facturación bruta (`$391,721.91`), pero supera a Central en ganancia neta por más de `$7,000`.

---

