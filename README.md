# ¿Cómo estimar el índice de Theil con la GEIH?

Proyecto de Estadística — Universidad del Rosario, 2026-II
Gabriel Salcedo, Jerónimo Marín, Isaac Suarez y Santiago Velandia

Comparamos cuatro estimadores del índice de Theil (A ponderado, B sin ponderar, C lognormal por momentos, D lognormal por máxima verosimilitud) con un experimento de simulación sobre la GEIH, y con el estimador validado medimos la desigualdad del ingreso laboral en Colombia, 2018–2026 (meses 1 a 6 de cada año).

---

## Inicio rápido (para reproducir el Theil sin descargar nada del DANE)

1. Clona el repositorio y abre `statistics_geih.Rproj` en RStudio (así funciona `here()`).
2. Instala los paquetes:
   ```r
   install.packages(c("here", "dplyr", "tidyr", "ggplot2", "scales", "haven"))
   ```
3. Verifica que tienes los datos completos:
   ```r
   source("scripts/00_verificar_datos.R")   # debe terminar en "TODO CORRECTO"
   ```
4. Corre el Theil y la descriptiva:
   ```r
   source("scripts/03_theil.R")                 # -> data/resultados/
   source("scripts/04_estadistica_descriptiva.R") # -> outputs/descriptiva/
   ```

Los pasos 01 y 02 **no** hacen falta para esto: sus resultados ya están en el repositorio.

---

## Estructura

```
statistics-geih/
├── data/
│   ├── raw/          Microdatos DANE por mes (YYYYMM/). NO está en GitHub (~65 GB).
│   ├── final/        Etapa 1: base cruda unida, una por año (base_<año>.rds) + reportes/
│   ├── analitica/    Etapa 2: base analítica, una por año (analitica_<año>.rds) + reportes/
│   └── resultados/   Etapa 3: theil_resumen.csv y theil_grupos.csv
├── outputs/descriptiva/   Etapa 4: tablas/ (.csv) y figuras/ (.png)
├── scripts/          Código, en el orden en que se corre
├── docs/             Diccionario de datos GEIH y estado del proyecto
└── report/           Informe y presentación (LaTeX)
```

> Ojo con el nombre: `data/final` **no** es la base final del análisis; es la base cruda unida (etapa 1). La que se usa para el Theil es `data/analitica`.

## Scripts (orden de ejecución)

| Script | Entrada | Salida | ¿Hay que correrlo? |
|---|---|---|---|
| `00_verificar_datos.R` | `data/final`, `data/analitica`, `data/resultados` | mensajes OK/FALLA | Sí, primero |
| `01_base_cruda_anual.R` | `data/raw` | `data/final/base_<año>.rds` | Solo con los microdatos |
| `02_base_analitica_anual.R` | `data/final` | `data/analitica/analitica_<año>.rds` | Opcional (no necesita microdatos) |
| `03_theil.R` | `data/analitica` | `data/resultados/*.csv` | Sí |
| `04_estadistica_descriptiva.R` | `data/analitica` | `outputs/descriptiva/` | Sí |
| `03_ejemplo_theil.R` | — | consola | Ejemplo didáctico de la descomposición |

## Cómo usar la base analítica

Principio de la etapa 2: **marcar, no borrar**. La base analítica tiene a *todos* los ocupados; la población de estudio se elige con indicadores:

```r
library(dplyr); library(here)
b <- readRDS(here("data", "analitica", "analitica_2024.rds")) %>%
  filter(en_poblacion, responde)          # quienes entran al Theil
# pesos: fex_aj (FEX ajustado por no respuesta de ingreso)
```

| Variable | Qué es |
|---|---|
| `ingreso` | Ingreso laboral mensual (INGLABO), pesos corrientes |
| `FEX` | Factor de expansión original (fex_c_2011 en 2018–2021, FEX_C18 desde 2022) |
| `fex_aj` | FEX ajustado por no respuesta de ingreso (celdas de posición × formalidad × educación × región × sexo). Peso principal |
| `fex_aj_nac` | Igual, pero con cobertura nacional completa (útil desde 2022) |
| `educ`, `formal`, `sexo`, `region`, `estrato` | Las cinco dimensiones de la descomposición |
| `posicion`, `tam_empresa`, `edad`, `horas`, `DPTO`, `CLASE` | Descriptivas y celdas de ajuste |
| `f_edad`, `f_remunerado`, `f_cobertura`, `f_no_cero`, `f_dims` | Cada filtro por separado |
| `en_poblacion` | Todos los filtros anteriores a la vez |
| `responde` | Reporta ingreso > 0 |

Escalas de medición: `data/analitica/diccionario_variables.csv`.
Cuántas personas quita cada filtro: `data/analitica/reportes/trazabilidad_<año>.csv`.

## Decisiones que hay que conocer

- **Meses 1 a 6** de cada año (no enero–julio).
- **2020 se excluye del Theil**: en la recolección telefónica falta el ingreso de la mayoría de los ocupados y no hay estrato.
- **Cobertura común de 24 departamentos** para que 2018–2021 (marco antiguo) y 2022–2026 (marco 2018) sean comparables. Por eso la región Orinoquía-Amazonía y San Andrés no entran en la serie.
- **Factores de expansión de dos marcos distintos** (ver tabla de arriba). El salto del Theil entre 2021 y 2022 puede deberse en parte a ese cambio.
- **Formalidad** = cotiza a pensión o ya es pensionado (P6920 = 1 o 3).
- **Ingreso 0** queda fuera de la población (el Theil usa logaritmos).

## Para quien tenga los microdatos

Descarga desde https://microdatos.dane.gov.co la GEIH de cada mes (formato .dta) y guarda cada mes en `data/raw/YYYYMM/` con los nombres originales del DANE. 2018, 2019 y 2021 vienen en archivos Área / Cabecera / Resto; los demás años, en un archivo nacional. Luego corre `01` y `02`.
