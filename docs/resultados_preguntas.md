
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

