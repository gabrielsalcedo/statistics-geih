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
2. Instala los paquetes, una sola vez. Al abrir el proyecto, `renv` se activa solo; con
   esta línea instala las mismas versiones que usamos (están en `renv.lock`):
   ```r
   renv::restore()
   ```
   Si `renv` da problemas, también sirve instalarlos a mano:
   `install.packages(c("here", "dplyr", "tidyr", "ggplot2", "scales", "quantreg", "testthat"))`.
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
| 1 | `scripts/01_base_cruda.R` | `data/raw/` | `data/intermedia/etapa1_cruda/*.rds` + `reportes/` | Sí |
| 2 | `scripts/02_base_analitica.R` | `data/intermedia/etapa1_cruda/` | `data/intermedia/etapa2_analitica/*.rds` + `reportes/` | Sí (usa el paso 1) |
| 3 | `scripts/03_exportar_procesados.R` | `data/intermedia/etapa2_analitica/` | `data/processed/*.csv.gz`, `data/checksums.txt` | Sí (usa el paso 2) |
| 4 | `scripts/04_verificar_datos.R` | `data/processed/` | mensajes OK/FALLA | No |
| 5 | `scripts/05_theil.R` | `data/processed/` | `data/resultados/theil_*.csv` | No |
| 6 | `scripts/06_descriptiva.R` | `data/processed/` | `outputs/tablas/`, `outputs/figuras/` | No |
| 7 | `scripts/07_inferencia_clasica.R` | `data/processed/` | `outputs/tablas/p*`, `outputs/figuras/p*` | No |

`run_all.R` corre los pasos 4 a 7 y las pruebas (después del paso 4). Con
`desde_crudos <- TRUE` corre antes los pasos 1 a 3.

## Estructura

```
statistics-geih/
├── run_all.R              Corre todo el proyecto
├── renv.lock              Versiones exactas de los paquetes (renv::restore())
├── R/                     Funciones (sin efectos al cargarlas)
│   ├── config.R           Años, dimensiones y demás constantes comunes
│   ├── datos.R            Leer y escribir data/processed/
│   ├── theil.R            Estimadores A, B, C, D y descomposición
│   └── salidas.R          Guardar tablas (.csv + .tex) y figuras (.pdf)
├── scripts/               Pasos del análisis: el número es el orden de ejecución
├── tests/testthat/        Pruebas: testthat::test_dir("tests/testthat")
├── data/
│   ├── raw/               Microdatos del DANE (NO están en GitHub; ver README de la carpeta)
│   ├── intermedia/etapa1_cruda/reportes/      Controles de la unión de módulos
│   ├── intermedia/etapa2_analitica/reportes/  Trazabilidad de filtros y celdas del ajuste
│   ├── processed/         Bases analíticas en CSV (versionadas)
│   ├── resultados/        Theil por año, peso y dimensión
│   ├── codebook.md        Libro de códigos
│   └── checksums.txt      Huellas MD5 de data/processed/
├── outputs/figuras/       Figuras en PDF (las incluye LaTeX con \includegraphics)
├── outputs/tablas/        Tablas en .tex (las incluye LaTeX con \input) y en .csv
├── docs/                  Auditoría, estado del proyecto, diccionario DANE y entregas
└── _revisar/              Archivos de prueba antiguos, pendientes de que el equipo decida
```

## Cómo se reproduce cada resultado

| Resultado | Lo genera | Archivo |
|---|---|---|
| Tabla 2 de la entrega (trazabilidad) | `02_base_analitica.R` | `data/intermedia/etapa2_analitica/reportes/trazabilidad_<año>.csv` |
| Theil A y B por año; porcentaje explicado por dimensión | `05_theil.R` | `data/resultados/theil_resumen.csv` |
| Detalle por grupo de cada descomposición | `05_theil.R` | `data/resultados/theil_grupos.csv` |
| Medidas, frecuencias, tablas cruzadas y evolución | `06_descriptiva.R` | `outputs/tablas/01_…` a `06_…` (.tex y .csv) |
| Figuras de la descriptiva | `06_descriptiva.R` | `outputs/figuras/03_…` a `07c_…` (.pdf) |
| Intervalos y pruebas clásicas (P1–P7): IC, t, F, χ², regresión, normalidad | `07_inferencia_clasica.R` | `outputs/tablas/resumen_pruebas.tex`, `outputs/tablas/p*`, `outputs/figuras/p*` |

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
