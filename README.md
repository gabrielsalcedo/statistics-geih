# ¿Cómo estimar el índice de Theil con la GEIH?

Proyecto de Estadística (73210011) — Universidad del Rosario, 2026-II
Gabriel Salcedo, Jerónimo Marín, Isaac Suarez y Santiago Velandia

Comparamos cuatro estimadores del índice de Theil con un experimento de simulación sobre la
GEIH: A ponderado, B sin ponderar, C lognormal por momentos y D lognormal por máxima
verosimilitud. Con el estimador validado medimos y descomponemos la desigualdad del ingreso
laboral en Colombia, 2018–2026 (meses 1 a 6 de cada año).

---

## Inicio rápido (sin descargar nada del DANE)

1. Clona el repositorio y abre `statistics_geih.Rproj` en RStudio. Así `here()` encuentra
   las carpetas.
2. Instala los paquetes, una sola vez:
   ```r
   install.packages(c("here", "dplyr", "tidyr", "ggplot2", "scales", "quantreg", "testthat"))
   ```
3. Corre todo:
   ```r
   source("run_all.R")
   ```
   El script verifica los datos (debe decir "TODO CORRECTO"), corre las pruebas y genera
   el Theil y la estadística descriptiva. Tarda unos minutos.

Las bases ya están en el repositorio, en `data/processed/` (unos 51 MB en total). No hace
falta descargar los microdatos del DANE (62 GB) a menos que quieras reconstruirlas desde
cero (ver `data/raw/README.md`).

---

## Pregunta e hipótesis

**Pregunta.** De los cuatro estimadores, ¿cuál tiene mejores propiedades estadísticas
(menor sesgo, menor ECM y consistencia) para estimar la desigualdad del ingreso laboral a
partir de la GEIH?

- **H1.** A es consistente y tiene el menor ECM cuando n crece; B, C y D no convergen al
  valor verdadero. Se prueba con una t pareada sobre las réplicas de la simulación.
- **H2.** En 2026, la educación explica más desigualdad (componente "entre") que cada una de
  las otras cuatro dimensiones.
- **H3.** La desigualdad del ingreso laboral fue menor en 2026 que en 2018.

La redacción completa está en `docs/curso/report/primera_entrega_corregida.tex`.

## Datos

- **Fuente:** DANE, Gran Encuesta Integrada de Hogares (GEIH), microdatos mensuales,
  <https://microdatos.dane.gov.co>.
- **Población:** ocupados de 15 años o más, remunerados, con ingreso laboral positivo, en
  los 24 departamentos comunes a todos los años.
- **Bases:** `data/processed/geih_<año>.csv.gz`, una por año, con todos los ocupados y
  los indicadores para elegir la población. Las variables están descritas en
  `data/codebook.md`.
- **Lectura:**
  ```r
  source("R/datos.R")
  b <- cargar_analitica(2024)
  b <- b[b$en_poblacion & b$responde, ]   # quienes entran al Theil; peso: fex_aj
  ```

## Orden de ejecución

| Paso | Script | Entrada | Salida | ¿Necesita los .dta? |
|---|---|---|---|---|
| 1 | `scripts/01_base_cruda_anual.R` | `data/raw/` | `data/final/*.rds` + `reportes/` | Sí |
| 2 | `scripts/02_base_analitica_anual.R` | `data/final/` | `data/analitica/*.rds` + `reportes/` | Sí (usa el paso 1) |
| 2b | `scripts/02b_exportar_procesados.R` | `data/analitica/` | `data/processed/*.csv.gz`, `data/checksums.txt` | Sí (usa el paso 2) |
| 0 | `scripts/00_verificar_datos.R` | `data/processed/` | mensajes OK/FALLA | No |
| 3 | `scripts/03_theil.R` | `data/processed/` | `data/resultados/theil_*.csv` | No |
| 4 | `scripts/04_estadistica_descriptiva.R` | `data/processed/` | `outputs/descriptiva/` | No |

`run_all.R` corre 0, las pruebas, 3 y 4. Con `desde_crudos <- TRUE` corre antes 1, 2 y 2b.

## Estructura

```
statistics-geih/
├── run_all.R              Corre todo el proyecto
├── R/                     Funciones (sin efectos al cargarlas)
│   ├── config.R           Años, dimensiones y demás constantes comunes
│   ├── datos.R            Leer y escribir data/processed/
│   └── theil.R            Estimadores A, B, C, D y descomposición
├── scripts/               Pasos del análisis, en orden
├── tests/testthat/        Pruebas: testthat::test_dir("tests/testthat")
├── data/
│   ├── raw/               Microdatos del DANE (NO están en GitHub; ver README de la carpeta)
│   ├── final/reportes/    Etapa 1: controles de la unión de módulos
│   ├── analitica/reportes/  Etapa 2: trazabilidad de filtros y celdas del ajuste
│   ├── processed/         Bases analíticas en CSV (versionadas)
│   ├── resultados/        Theil por año, peso y dimensión
│   ├── codebook.md        Libro de códigos
│   └── checksums.txt      Huellas MD5 de data/processed/
├── outputs/descriptiva/   Tablas (.csv) y figuras (.png) de la descriptiva
├── docs/                  Auditoría, estado del proyecto, diccionario DANE y entregas
└── _revisar/              Archivos de prueba antiguos, pendientes de que el equipo decida
```

## Cómo se reproduce cada resultado

| Resultado | Lo genera | Archivo |
|---|---|---|
| Tabla 2 de la entrega (trazabilidad) | `02_base_analitica_anual.R` | `data/analitica/reportes/trazabilidad_<año>.csv` |
| Theil A y B por año; porcentaje explicado por dimensión | `03_theil.R` | `data/resultados/theil_resumen.csv` |
| Detalle por grupo de cada descomposición | `03_theil.R` | `data/resultados/theil_grupos.csv` |
| Medidas, frecuencias, tablas cruzadas y evolución | `04_estadistica_descriptiva.R` | `outputs/descriptiva/tablas/` |
| Figuras de la descriptiva | `04_estadistica_descriptiva.R` | `outputs/descriptiva/figuras/` |

Los números de referencia (para comprobar que obtienes lo mismo) están en `CLAUDE.md`,
sección 9.

## Decisiones que hay que conocer

- **Meses 1 a 6** de cada año.
- **2020 se excluye del Theil:** en la recolección telefónica falta el ingreso de la
  mayoría de los ocupados y no hay estrato.
- **Cobertura común de 24 departamentos,** para que 2018–2021 (marco antiguo) y 2022–2026
  (marco 2018) sean comparables.
- **Factores de expansión de dos marcos:** `FEX_C_2011` hasta 2021 y `FEX_C18` desde 2022.
  El salto del Theil entre 2021 y 2022 puede deberse en parte a ese cambio.
- **No respuesta de ingreso:** no se borra a nadie. Su peso se reparte entre quienes sí
  responden, dentro de celdas de posición, formalidad, educación, región y sexo (`fex_aj`).
- **Formalidad:** cotiza a pensión o ya es pensionado (`P6920` = 1 o 3).
- **Ingreso 0:** queda fuera de la población, para que los cuatro estimadores comparen la
  misma población. El estimador D usa ln y, que no existe en 0.

Las decisiones abiertas y los hallazgos de la revisión están en `docs/AUDITORIA.md`.
