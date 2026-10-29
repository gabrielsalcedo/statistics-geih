# ¿Cómo estimar el índice de Theil con la GEIH?

Proyecto de Estadística — Universidad del Rosario, 2026-II
Gabriel Salcedo, Jerónimo Marín, Isaac Suarez y Santiago Velandia

Comparamos cuatro estimadores del índice de Theil (A con factor de expansión, B sin
factor, C lognormal por momentos y D lognormal por máxima verosimilitud) con un
experimento de simulación, y usamos el mejor para medir y descomponer la desigualdad
del ingreso laboral en Colombia entre 2018 y 2026 con la GEIH del DANE.

## Estructura

```
statistics-geih/
├── data/
│   ├── raw/      geih_cruda_<año>.csv.gz: todos los ocupados de enero a junio, tres módulos unidos
│   └── final/    geih_<año>.csv.gz: bases depuradas, con el factor ajustado por no respuesta
├── outputs/      tablas de resultados en CSV
├── scripts/      código en R (00 a 06 y correr_todo.R)
├── latex/        informe.tex, beamer.tex, references.bib, logo y figuras .png
├── README.md
└── statistics-geih.Rproj
```

| Script | Qué hace |
|---|---|
| `00_funciones.R` | Estimadores A, B, C y D, descomposición entre/dentro y lectura de las bases |
| `01_extraer_crudas.R` | De los .dta del DANE a `data/raw` (opcional, ver abajo) |
| `02_bases_finales.R` | De `data/raw` a `data/final`: armonización, depuración y ajuste por no respuesta |
| `03_descriptiva.R` | Frecuencias, medidas, tablas cruzadas, histograma y diagramas de caja |
| `04_theil_anual.R` | Theil por año y descomposición por cinco dimensiones |
| `05_simulacion.R` | Experimento Monte Carlo (H1) |
| `06_bootstrap.R` | Intervalos de confianza, H2 y H3 |
| `correr_todo.R` | Corre 02 a 06 en orden |

## Cómo replicar

No hace falta descargar nada del DANE: las crudas ya están en `data/raw`.

1. **Descargar el repositorio:** en GitHub, *Code > Download ZIP* (y descomprimir), o
   clonarlo con GitHub Desktop.
2. **Instalar R y RStudio.** Usamos R 4.5.2 (<https://cran.r-project.org>) y RStudio
   (<https://posit.co/download/rstudio-desktop/>).
3. **Instalar los paquetes** (una sola vez), en la consola de R:
   ```r
   install.packages(c("dplyr", "tidyr", "ggplot2", "scales", "quantreg"))
   ```
4. **Abrir `statistics-geih.Rproj`** (doble clic). Así R trabaja desde la carpeta del
   proyecto. Luego, en la consola:
   ```r
   source("scripts/correr_todo.R")
   ```
5. **Qué se genera:**
   - `data/final/geih_<año>.csv.gz`: las nueve bases finales.
   - `outputs/*.csv`: trazabilidad de la depuración (Tabla 2), descriptivas, Theil,
     simulación y bootstrap.
   - `latex/fig_*.png`: las figuras del informe.

   Tiempos aproximados: 02 ≈ 2 min, 03 ≈ 1 min, 04 ≈ 1 min,
   05 (simulación) ≈ 0,5 min y 06 (bootstrap) ≈ 6 min. En total, unos 10 minutos.
6. **Compilar el informe y la presentación:**
   - Overleaf: subir la carpeta `latex/` completa y compilar `informe.tex` o `beamer.tex`
     (Overleaf usa biber automáticamente).
   - En el computador: dentro de `latex/`, `pdflatex → biber → pdflatex → pdflatex`.

Los resultados son idénticos en cualquier computador: la simulación y el bootstrap usan
semillas fijas.

## Regenerar las crudas desde el DANE (opcional)

1. Descargar los microdatos de la Gran Encuesta Integrada de Hogares desde el catálogo
   del DANE: <https://microdatos.dane.gov.co>.
2. Para cada año 2018–2026 y cada mes 1 a 6, guardar en una carpeta `AAAAMM/` (por
   ejemplo `201801/`) los módulos, en formato Stata y con sus nombres originales:
   - Ocupados;
   - Características generales (personas);
   - Datos del hogar y la vivienda ("Vivienda y Hogares" en los años antiguos).

   En 2018, 2019 y 2021 cada módulo viene en tres archivos (Área, Cabecera y Resto).
3. Poner la ruta de esa carpeta en la variable `carpeta_dta`, al inicio de
   `scripts/01_extraer_crudas.R`, y correrlo: `source("scripts/01_extraer_crudas.R")`
   (≈ 5 min). Necesita además el paquete `haven`.

## Decisiones principales de la depuración

- Meses 1 a 6 de cada año, 2018–2026. **2020 no entra al Theil:** en la recolección
  telefónica falta el ingreso de la mayoría y no hay estrato.
- **Población:** ocupados de 15 años o más, remunerados, con ingreso laboral positivo, en
  los 24 departamentos comunes a todos los años.
- **Ingreso:** `INGLABO`, en pesos corrientes (el Theil no depende de la escala).
- **Factor de expansión:** `FEX_C_2011` en 2018–2021 y `FEX_C18` en 2022–2026.
- **No respuesta de ingreso:** no se borra a nadie. Su peso se reparte entre quienes sí
  responden, dentro de celdas de posición, formalidad, educación, región y sexo (`fex_aj`).
- **Formalidad:** cotiza a pensión o ya es pensionado (`P6920` = 1 o 3).
- **Educación:** cinco niveles comunes a los dos marcos.

**Fuente de los datos:** Departamento Administrativo Nacional de Estadística (DANE),
Gran Encuesta Integrada de Hogares (GEIH), microdatos 2018–2026.
