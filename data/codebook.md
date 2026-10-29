# Libro de códigos — `data/processed/geih_<año>.csv.gz`

Un archivo por año (2018–2026). Cada uno contiene a **todos los ocupados de los meses 1 a 6**
de la GEIH de ese año: una fila por persona y por mes. No se borra a nadie: la población de
estudio se elige con los indicadores `f_*`, `en_poblacion` y `responde`.

- **Fuente:** Departamento Administrativo Nacional de Estadística (DANE), Gran Encuesta
  Integrada de Hogares (GEIH), microdatos mensuales. Cómo obtenerlos: `data/raw/README.md`.
- **Construcción:** `scripts/01_base_cruda.R` → `02_base_analitica.R` →
  `03_exportar_procesados.R`.
- **Lectura en R:** `source("R/datos.R"); b <- cargar_analitica(2024)`. Devuelve los factores
  con sus categorías en orden.
- **Formato:** CSV en UTF-8 comprimido con gzip, separador coma y faltantes como `NA`.
  Integridad: `data/checksums.txt` (MD5).

Las cinco dimensiones de la descomposición son `educ`, `formal`, `sexo`, `region` y
`estrato`.

## Identificación

| Variable | Descripción | Tipo | Variable GEIH |
|---|---|---|---|
| `ANIO` | Año de la encuesta | Entero | — |
| `MES` | Mes de la encuesta (1 a 6) | Entero | Carpeta del archivo |
| `DIRECTORIO` | Identificador de la vivienda | Texto | `DIRECTORIO` |
| `SECUENCIA_P` | Secuencia del hogar en la vivienda | Texto | `SECUENCIA_P` |
| `HOGAR` | Número del hogar | Texto | `HOGAR` |
| `ORDEN` | Número de la persona en el hogar | Texto | `ORDEN` |

La llave de una persona es (`MES`, `DIRECTORIO`, `SECUENCIA_P`, `HOGAR`, `ORDEN`).

## Factores de expansión

| Variable | Descripción | Tipo | Variable GEIH |
|---|---|---|---|
| `FEX` | Factor de expansión original | Continua, razón | `FEX_C_2011` (2018–2019, 2021); `FEX_C` (2020); `FEX_C18` (2022–2026) |
| `fex_aj` | FEX ajustado por no respuesta de ingreso, cobertura común de 24 departamentos. **Peso principal.** Vale 0 si la persona no reporta ingreso y NA fuera de la población | Continua, razón | Calculado |
| `fex_aj_nac` | Igual que `fex_aj`, pero con cobertura nacional completa | Continua, razón | Calculado |
| `celda_aj` | Celda del ajuste por no respuesta (`N1` es la más fina y `N6`, la de respaldo) | Texto | Calculado |

Los factores suman la población de los seis meses. Para obtener ocupados por mes se divide
entre 6.

## Variables cuantitativas

| Variable | Descripción | Tipo / escala | Variable GEIH |
|---|---|---|---|
| `ingreso` | Ingreso laboral mensual, pesos corrientes (sin deflactar). NA = no reporta | Continua, razón | `INGLABO` |
| `edad` | Edad en años cumplidos | Discreta, razón | `P6040` |
| `horas` | Horas trabajadas a la semana en el empleo principal | Discreta, razón | `P6800` |

## Variables cualitativas

| Variable | Descripción | Escala | Categorías | Variable GEIH |
|---|---|---|---|---|
| `sexo` | Sexo | Nominal | Hombre (1), Mujer (2) | `P6020` (hasta 2021); `P3271` (desde 2022) |
| `educ` | Máximo nivel educativo, armonizado entre marcos | Ordinal | Ninguno/preescolar < Primaria < Secundaria < Media < Superior | `P6210` (hasta 2021, códigos 1–6; 9 = NA); `P3042` (desde 2022, códigos 1–13; 99 = NA) |
| `formal` | Formal si cotiza a pensión o ya es pensionado | Nominal | Formal (`P6920` = 1 o 3), Informal (`P6920` = 2) | `P6920` |
| `region` | Región según el departamento | Nominal | Bogotá, Caribe, Oriental, Central, Pacífica, Orinoquía-Amazonía (vacía en la cobertura común) | `DPTO` |
| `estrato` | Estrato de la vivienda para la tarifa de energía | Ordinal | 1 < 2 < … < 6 (0 y 9 = NA) | `P4030S1A1` (no existe en 2020) |
| `posicion` | Posición ocupacional agrupada | Nominal | Asalariado privado (1, 8), Gobierno (2), Doméstico (3), Cuenta propia (4, 9), Patrón (5), Sin remuneración (6, 7) | `P6430` |
| `tam_empresa` | Personas en la empresa, en rangos comunes a los dos marcos | Ordinal | Trabaja solo < 2 a 5 < 6 a 10 < 11 a 50 < 51 o más | `P6870` (hasta 2021); `P3069` (desde 2022) |
| `DPTO` | Código DANE del departamento | Nominal | 5 = Antioquia, 11 = Bogotá, … | `DPTO` |
| `CLASE` | Zona | Nominal | 1 = Cabecera, 2 = Resto | `CLASE` |

> **Atención con `posicion` desde 2022:** el código 7 de `P6430` corresponde en los datos a
> trabajadores con ingreso (jornaleros), no a trabajadores sin remuneración. Ver
> `docs/AUDITORIA.md` §2.9 (decisión D10). Hoy se clasifican como "Sin remuneración".

## Indicadores de población (TRUE/FALSE)

| Variable | Condición |
|---|---|
| `f_edad` | 15 años o más |
| `f_remunerado` | `posicion` distinta de "Sin remuneración" |
| `f_cobertura` | Departamento dentro de los 24 comunes a todos los años |
| `f_no_cero` | Ingreso distinto de 0 (NA cuenta como TRUE: es no respuesta, no cero) |
| `f_dims` | Las cinco dimensiones y `posicion` sin NA (en 2020, sin exigir estrato) |
| `responde` | Reporta ingreso mayor que 0 |
| `en_poblacion` | Todos los `f_*` a la vez: la población de estudio |
| `en_poblacion_nac` | Igual que `en_poblacion`, pero sin la restricción de cobertura |

Las personas que entran al Theil son `en_poblacion & responde`, con peso `fex_aj`.
