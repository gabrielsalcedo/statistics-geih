# Microdatos crudos de la GEIH (no están en GitHub)

Esta carpeta guarda los microdatos originales del DANE: unos 62 GB y 710 archivos `.dta`.
No se suben a GitHub, porque varios archivos pesan más de 100 MB. **Para correr el Theil y la
descriptiva no hacen falta:** basta con `data/processed/`.

Solo se necesitan para reconstruir las bases desde cero (`scripts/01_base_cruda.R`).

## Fuente

Departamento Administrativo Nacional de Estadística (DANE). *Gran Encuesta Integrada de
Hogares (GEIH)*. Microdatos mensuales, 2018–2026. Catálogo de microdatos del DANE:
<https://microdatos.dane.gov.co>.

## Cómo descargarlos

1. En el catálogo de microdatos, busca "Gran Encuesta Integrada de Hogares" y abre el año.
2. Descarga, para los meses **1 a 6**, los módulos en formato Stata (`.dta`):
   - Ocupados;
   - Características generales (personas);
   - Datos del hogar y la vivienda ("Vivienda y Hogares" en los años antiguos).
3. Guarda cada mes en su propia carpeta `data/raw/AAAAMM/` (por ejemplo `data/raw/201801/`),
   **con los nombres originales** del DANE. No renombres ni conviertas los archivos.

| Años | Cómo vienen los archivos |
|---|---|
| 2018, 2019, 2021 | Tres archivos por módulo: `Area - …`, `Cabecera - …`, `Resto - …` |
| 2020, 2022–2026 | Un archivo nacional por módulo (por ejemplo `Ocupados.DTA`) |

En 2020 no se usa el módulo de vivienda: la recolección telefónica no incluyó el estrato.

## Cómo regenerar las bases

Con los microdatos en su lugar, desde la raíz del proyecto en R:

```r
source("run_all.R")   # con desde_crudos <- TRUE al inicio del archivo
```

O paso a paso:

```r
source("scripts/01_base_cruda.R")       # data/raw      -> data/final/*.rds   (~5 min)
source("scripts/02_base_analitica.R")   # data/final    -> data/analitica/*.rds
source("scripts/03_exportar_procesados.R")   # data/analitica -> data/processed/*.csv.gz
```

Si los archivos son los mismos, los CSV salen idénticos byte a byte y
`scripts/04_verificar_datos.R` termina en "TODO CORRECTO".
