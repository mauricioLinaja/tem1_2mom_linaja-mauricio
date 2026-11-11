

## 1. Conclusiones Técnicas (Ingeniería de Datos y Dominio de HiveQL)

1. **Importancia critica del serializador `OpenCSVSerde` en la ingesta:**
   La verificación previa del archivo `Sample - Superstore.csv` demostró que **2,221 registros (22.22%)** contienen comas internas dentro del nombre del producto entre comillas dobles. Diseñar una capa *Staging* con `OpenCSVSerde` antes de volcar los datos hacia la tabla analítica evitó la corrupción estructural de más de una quinta parte del dataset.
2. **Tipado estricto y almacenamiento columnar `ORC`:**
   La conversión explícita de fechas desde el formato `M/d/yyyy` hacia `DATE` (`yyyy-MM-dd`) y de importes monetarios hacia `DECIMAL(12,4)` sobre almacenamiento columnar **ORC comprimido con Snappy** redujo la huella en HDFS en un **82.0%** (de `2.29 MB` a `412 KB`) y aceleró más de **3 veces** la ejecución de consultas analíticas complejas.


## 2. Conclusiones Estratégicas para la Toma de Decisiones de Negocio

1. **Reforma inmediata de la política de descuentos comerciales (Hallazgo más rentable):**
   El análisis de la Pregunta 6 demostró que el **100% de las ventas sin descuento** son rentables (margen del `29.51%`, aportando `+$320,987.60`), y con descuentos de hasta el **20%** el margen sigue siendo positivo (`11.91%`, aportando `+$100,785.47`). Sin embargo, cuando el descuento supera el **20%**, el **96.77% de las transacciones pierden dinero**, destruyendo **`-$135,376.05`** de utilidad neta. **Recomendación:** Establecer en el sistema ERP/POS un tope máximo de descuento del **20%** (especialmente en las subcategorías `Tables`, `Bookcases`, `Machines` y `Binders`).
2. **Intervención focalizada en la Región Central:**
   Aunque la región **Central** factura `$501,239.89` (superando a `South`), su margen de rentabilidad es de apenas **`7.92%`** (`$39,706.36`), casi la mitad del margen de la región líder **West** (`14.94%`, `$108,418.45`). Esto se debe al exceso de descuentos aplicados en Texas e Illinois dentro de la región Central.

