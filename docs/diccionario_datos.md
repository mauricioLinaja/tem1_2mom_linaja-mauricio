
## 1. Inspección Técnica Previa del Archivo CSV

Antes de diseñar el esquema físico en Apache Hive, se realizó una auditoría estructural sobre el archivo original `Sample - Superstore.csv` (descargado de Kaggle: `vivek468/superstore-dataset-final`):

1. **Volumen y Estructura:** 9,994 registros de detalle transaccional (líneas de pedido) más 1 fila de encabezado (`9,995` líneas físicas), distribuidos en **21 columnas**.
2. **Codificación de caracteres:** `Windows-1252` (`ISO-8859-1` / `Latin-1`), requerida para preservar caracteres especiales en nombres de productos y clientes.
3. **Comas embebidas dentro de campos entrecomillados:** Se detectaron **2,221 registros (22.22% del dataset)** cuyos valores en la columna `Product Name` contienen comas internas encerradas entre comillas dobles `"` (por ejemplo, fila 2: `"Hon Deluxe Fabric Upholstered Stacking Chairs, Rounded Back"`).
   - **Decisión de Ingeniería:** Si se utilizara el delimitador simple por defecto (`ROW FORMAT DELIMITED FIELDS TERMINATED BY ','`), `LazySimpleSerDe` dividiría erróneamente el nombre del producto en dos o más columnas, desplazando hacia la derecha los campos numéricos (`Sales`, `Quantity`, `Discount`, `Profit`) y generando valores `NULL` o corruptos. Por ello, la capa de ingesta utiliza obligatoriamente **`org.apache.hadoop.hive.serde2.OpenCSVSerde`**.
4. **Formato de Fechas:** Las columnas `Order Date` y `Ship Date` están expresadas en formato estadounidense sin ceros a la izquierda **`M/d/yyyy`** (ej. `11/8/2016`, `6/12/2016`). Dado que el tipo nativo `DATE` de Apache Hive exige el estándar ISO **`yyyy-MM-dd`**, se realiza la conversión explícita en la capa analítica mediante `TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(campo, 'M/d/yyyy')))`.
5. **Códigos Postales (`Postal Code`):** Deben almacenarse como `STRING` y no como `INT`, ya que en Estados Unidos existen códigos postales que inician con el dígito `0` (región Este/Nueva Inglaterra, como `05401` en Burlington, Vermont), los cuales perderían su cero inicial si se convirtieran a entero.

---

## 2. Diccionario de Datos Detallado (21 Campos)

| # | Campo Original CSV | Nombre Columna Hive | Tipo en Staging (`OpenCSVSerde`) | Tipo en Tabla Analítica (`ORC`) | Descripción Funcional y Semántica | Formato / Ejemplo | Restricciones y Reglas de Integridad |
|---|---|---|---|---|---|---|---|
| 1 | `Row ID` | `row_id` | `STRING` | `INT` | Identificador secuencial único de cada registro o línea dentro del archivo CSV. | `1`, `2`, `9994` | `NOT NULL`, `UNIQUE` (`1` a `9994`), entero positivo (`> 0`). |
| 2 | `Order ID` | `order_id` | `STRING` | `STRING` | Código alfanumérico de la orden de compra. Una orden puede agrupar varios productos (`1:N`). | `CA-2016-152156`, `US-2015-108966` | `NOT NULL`, patrón `XX-YYYY-NNNNNN` (`5,009` órdenes únicas). |
| 3 | `Order Date` | `order_date` | `STRING` | `DATE` | Fecha en la que el cliente realizó el pedido comercial. | CSV: `11/8/2016` → Hive: `2016-11-08` | `NOT NULL`, formato ISO `yyyy-MM-dd`, rango `2014-01-03` a `2017-12-30`, `order_date <= ship_date`. |
| 4 | `Ship Date` | `ship_date` | `STRING` | `DATE` | Fecha efectiva de despacho/envío del pedido hacia el cliente. | CSV: `11/11/2016` → Hive: `2016-11-11` | `NOT NULL`, formato ISO `yyyy-MM-dd`, rango `2014-01-07` a `2018-01-05`, `ship_date >= order_date`. |
| 5 | `Ship Mode` | `ship_mode` | `STRING` | `STRING` | Modalidad logística de envío seleccionada para el pedido. | `Standard Class`, `Second Class`, `First Class`, `Same Day` | `NOT NULL`, dominio cerrado de 4 modalidades de envío. |
| 6 | `Customer ID` | `customer_id` | `STRING` | `STRING` | Identificador único del cliente comprador en el sistema comercial. | `CG-12520`, `DV-13045`, `SO-20335` | `NOT NULL`, patrón `AA-NNNNN` (`793` clientes únicos). |
| 7 | `Customer Name` | `customer_name` | `STRING` | `STRING` | Nombre completo (nombre y apellido) del cliente registrado. | `Claire Gute`, `Sean O'Donnell` | `NOT NULL`, longitud variable. |
| 8 | `Segment` | `segment` | `STRING` | `STRING` | Segmento comercial o tipo de cuenta al que pertenece el cliente. | `Consumer`, `Corporate`, `Home Office` | `NOT NULL`, dominio controlado de 3 segmentos. |
| 9 | `Country` | `country` | `STRING` | `STRING` | País donde se ubica el destino del pedido. | `United States` | `NOT NULL`, valor constante `'United States'` en todo el dataset. |
| 10 | `City` | `city` | `STRING` | `STRING` | Ciudad de entrega del pedido dentro de los Estados Unidos. | `Henderson`, `Los Angeles`, `New York City` | `NOT NULL` (`531` ciudades únicas). |
| 11 | `State` | `state` | `STRING` | `STRING` | Estado federado de entrega dentro de los Estados Unidos. | `Kentucky`, `California`, `Florida` | `NOT NULL` (`49` estados representados). |
| 12 | `Postal Code` | `postal_code` | `STRING` | `STRING` | Código postal (ZIP Code) de 5 dígitos de la dirección de entrega. | `'42420'`, `'90036'`, `'05401'` | `NOT NULL`, cadena numérica de 5 caracteres (preserva ceros a la izquierda). |
| 13 | `Region` | `region` | `STRING` | `STRING` | Macro-región geográfica y comercial de Estados Unidos. | `West`, `East`, `Central`, `South` | `NOT NULL`, dominio cerrado de 4 regiones comerciales. |
| 14 | `Product ID` | `product_id` | `STRING` | `STRING` | Código identificador del producto dentro del catálogo comercial. | `FUR-BO-10001798`, `TEC-CO-10004722` | `NOT NULL`, patrón `CAT-SUB-NNNNNNNN` (`1,862` códigos únicos). |
| 15 | `Category` | `category` | `STRING` | `STRING` | Categoría principal de negocio a la que pertenece el producto. | `Furniture`, `Office Supplies`, `Technology` | `NOT NULL`, dominio cerrado de 3 categorías principales. |
| 16 | `Sub-Category` | `sub_category` | `STRING` | `STRING` | Subcategoría o línea específica de producto dentro de su categoría. | `Bookcases`, `Chairs`, `Phones`, `Binders`, `Tables` | `NOT NULL`, dominio cerrado de `17` subcategorías. |
| 17 | `Product Name` | `product_name` | `STRING` | `STRING` | Nombre comercial descriptivo del artículo vendido. | `Canon imageCLASS 2200 Advanced Copier` | `NOT NULL`, puede contener comas, comillas y caracteres especiales. |
| 18 | `Sales` | `sales` | `STRING` | `DECIMAL(12,4)` | Importe monetario bruto de la venta de la línea de pedido (en USD). | `261.9600`, `731.9400`, `22638.4800` | `NOT NULL`, `sales > 0` (rango real: `0.4440` a `22638.4800`). |
| 19 | `Quantity` | `quantity` | `STRING` | `INT` | Cantidad de unidades físicas vendidas del producto en dicha línea. | `2`, `3`, `5`, `14` | `NOT NULL`, entero positivo `quantity >= 1` (rango real: `1` a `14`). |
| 20 | `Discount` | `discount` | `STRING` | `DECIMAL(5,2)` | Proporción de descuento comercial aplicado sobre la línea (en tanto por uno). | `0.00`, `0.20`, `0.45`, `0.80` | `NOT NULL`, intervalo válido `0.00 <= discount <= 1.00` (rango real: `0.00` a `0.80`). |
| 21 | `Profit` | `profit` | `STRING` | `DECIMAL(12,4)` | Ganancia o pérdida neta generada por la línea de venta en USD (`< 0` indica pérdida). | `41.9136`, `-383.0310`, `8399.9760` | `NOT NULL`, admite valores positivos, cero o negativos (rango real: `-6599.9780` a `8399.9760`). |

