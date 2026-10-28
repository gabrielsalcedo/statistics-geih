# Auditoría del repositorio

Rama `revision-general`. Este documento se completa por fases:

- Fase 1 (inventario): escrita el 28-10-2026.
- Fases 2 y 3 (datos, Theil y Monte Carlo): pendientes.
- Fase 4 (descriptiva y curso): pendiente.

Las referencias `archivo:línea` corresponden al commit `6c25cd9`.

---

## Fase 1 — Inventario

### 1.1 Lo que ya estaba verificado (`docs/ESTADO_PROYECTO.md`) y si sigue siendo cierto

| Verificación previa | ¿Sigue siendo cierta? | Cómo se comprobó |
|---|---|---|
| Uniones de módulos sin duplicados ni ocupados sin pareja | Sí | `01_base_cruda_anual.R` detiene la ejecución si encuentra duplicados (líneas 337, 429 y 633) o si cambian las filas (471). Los reportes `uniones_<año>.csv` existen para los 9 años. |
| `fex_aj` conserva el total del FEX | Sí | Lo comprueba `02_base_analitica_anual.R:241` con `stop()`. |
| Enero de 2018 = 27.693 ocupados (Cabecera 24.952 + Resto 2.741) | Pendiente | Se vuelve a correr en la Fase 2. |
| ~3.500 respondientes por año sin estrato quedan fuera | Pendiente | Se cuantifica en la Fase 2, punto 8. |
| Números de la Tabla 2 de la entrega | Sí: los nueve años coinciden fila por fila con `trazabilidad_<año>.csv` | Lectura de los CSV. |

### 1.2 Árbol real de carpetas

```
statistics-geih/
├── .gitignore  CLAUDE.md  README.md  statistics_geih.Rproj
├── .RData  .RDataTmp (3 MB)  .Rhistory        ← sesión de RStudio (ignorados)
├── data/
│   ├── raw/          710 .dta, 62 GB, 54 carpetas YYYYMM   (ignorado)
│   ├── final/        base_<año>.rds (9 × ~2,5 MB, ignorados) + reportes/ (36 CSV)
│   ├── analitica/    analitica_<año>.rds (9 × ~4,5 MB, ignorados) + reportes/ (27 CSV)
│   │                 + diccionario_variables.csv
│   └── resultados/   theil_resumen.csv, theil_grupos.csv
├── docs/
│   ├── DICCIONARIO_DATOS_GEIH_MARCO2018_T2 (5).xlsx
│   ├── ESTADO_PROYECTO.md
│   └── curso/        parametros proyecto.pdf + report/ (entrega .tex/.pdf, .bib, logo)
├── outputs/descriptiva/  tablas/ (10 CSV), figuras/ (6 PNG)
└── scripts/          00_ … 04_ (.R) + .Rhistory suelto
```

No existen: `report/` (el README lo menciona), `tests/`, `R/`, `renv`, `run_all.R`, ni
la retroalimentación del profesor.

**Estructura objetivo.** Se propone en la Fase 6 y se aplica solo con aprobación. Borrador:
`R/` (funciones), `scripts/` (numerados), `tests/`, `data/raw` (ignorada),
`data/processed/*.csv.gz` (versionados), `outputs/figures` (PDF), `outputs/tables`
(.tex), `report/`, `slides/`, `poster/` y `docs/`.

### 1.3 Scripts

#### `00_verificar_datos.R`, verificación para quien clona el repositorio
- **Qué hace.** Para cada año comprueba cuatro cosas: mismas filas y mismo orden entre la
  base cruda y la analítica, conteos iguales a la trazabilidad, que `fex_aj` conserve el
  FEX y que el Theil A coincida con `theil_resumen.csv`.
- **Entradas.** `data/final/*.rds`, `data/analitica/*.rds` y los reportes.
  **Salidas:** solo mensajes en consola.
- **Problema (importante).** Lee `data/final/base_<año>.rds` (`00_verificar_datos.R:43`).
  Desde el commit inicial esos `.rds` no se versionan, así que **en un clon nuevo este
  script falla**. Lo mismo vale para el README (líneas 17–27), que dice que los pasos 01
  y 02 "ya están en el repositorio". Se resuelve en la Fase 6 con los CSV de
  `data/processed/`.
- Repite la fórmula de Theil A (líneas 24–28) en lugar de usar la función de `03`. Es
  duplicación deliberada (para que funcione solo con R base), pero conviene comentarlo.
- `anios` está fijado en el código (línea 22). Debe salir de un archivo de configuración.

#### `01_base_cruda_anual.R`, etapa 1: unión de módulos y meses
- **Qué hace.** Lee Ocupados, Características generales y Vivienda de cada mes. En
  2018, 2019 y 2021 apila Cabecera + Resto y descarta Área tras verificar que Área está
  contenida en Cabecera. Une los módulos con llaves verificadas y guarda un `.rds` por
  año más cuatro reportes.
- **Calidad.** Es el script mejor construido: valida duplicados, parejas, FEX y DPTO
  entre módulos, y guarda el nombre original de las variables que cambian entre marcos.
- **Código muerto o efectos colaterales:**
  - `01_base_cruda_anual.R:711`: `inventario(2020, 1, buscar = ...)` **se ejecuta
    siempre** y exige que exista `data/raw/202001`. Es un diagnóstico que se dejó activo.
  - Líneas 718–725: bloque de prueba comentado.
  - `guardar_dta` (línea 32) nunca se usa con `TRUE`.
- **Constantes a configuración:** `anios`, `meses`, `anios_nacionales` (26–30).
- **Riesgo bajo, documentado.** En la línea 90 el orden de búsqueda del FEX pone
  `FEX_C18` antes que `FEX_C_2011`. Si un archivo trajera los dos, se usaría el del marco
  nuevo. Hoy no ocurre: los reportes `variables_<año>.csv` muestran `fex_c_2011` en
  2018–2021, `FEX_C` en 2020 y `FEX_C18` en 2022–2026, como se decidió.

#### `02_base_analitica_anual.R`, etapa 2: armonización, filtros y ajuste de pesos
- **Qué hace.**
  - Armoniza educación, tamaño de empresa y región con tablas de equivalencias.
  - Recodifica sexo, estrato, posición y formalidad.
  - Marca los filtros `f_*`, `en_poblacion` y `responde`.
  - Ajusta los pesos por no respuesta en celdas que pasan de lo fino a lo grueso
    (5 niveles, mínimo de 30 respondientes).
  - Guarda la base analítica, la trazabilidad, las celdas y la participación.
- **Comentarios desactualizados:**
  - Línea 76: "PENDIENTE: confirmar … 9 = no sabe".
  - Línea 109: "PENDIENTE: confirmar los rangos de P6870".
  - Línea 349: "PROPUESTA DE REGLA". La regla ya está decidida.
  - Cerrar o confirmar los dos pendientes con el diccionario del DANE (Fase 2).
- **Nivel "resto" (N6) del ajuste** (`02_base_analitica_anual.R:214`). Las filas que no
  alcanzan 30 respondientes ni siquiera por posición terminan en una sola celda que
  mezcla posiciones distintas. Por eso hay celdas con menos de 30 respondientes:
  6 en 2022, 20 en 2019 y 24 en 2025. Afecta pocas filas (6 a 133 por año) y los
  factores son ≤ 1,57, así que el impacto es bajo. Debe documentarse.
- **Factores de ajuste extremos.** Máximo 2,17 en 2018 ("Patrón | Formal | Superior |
  Caribe | Hombre": responde el 44,5 %) y 2,46 en 2020. Desde 2022 todos son ≤ 1,66.
- **Constantes a configuración:** `anios`, `edad_min`, `min_resp_celda`,
  `deptos_comunes` (23–37).
- `niveles_region` incluye "Orinoquía-Amazonía" (línea 141), que nunca aparece en la
  cobertura común. No es un error, porque `droplevels` y `dplyr` lo descartan, pero
  confunde. El departamento 88 (San Andrés) está en el Caribe (línea 145) y también
  queda fuera por cobertura.
- **Decisión metodológica visible** (línea 366). `f_dims` exige las cinco dimensiones,
  incluido el estrato. Quien no tiene estrato sale de *todas* las descomposiciones y del
  Theil total, no solo de la descomposición por estrato (decisión abierta, ver abajo).

#### `03_theil.R`, etapa 3: Theil A/B y descomposición
- **Qué hace.**
  - `theil_decomp(y, w, g)` calcula T, la media, el n efectivo de Kish y, si recibe
    grupos, T_B, T_W y S.
  - Corre cuatro pruebas hechas a mano con `stopifnot`.
  - Calcula cada año (sin 2020) con tres pesos: `fex_aj` (A), `FEX` (A sin ajuste) y
    1 (B).
- **Fórmulas.** Coinciden con la propuesta: within = Σ sₖTₖ y between = Σ sₖ ln(μₖ/μ).
  Además verifica que T = T_B + T_W (línea 102). La auditoría detallada es la Fase 3.
- **Lo que falta para el proyecto:** estimadores C y D, simulación Monte Carlo,
  bootstrap, pruebas de H1, H2 y H3. Las pruebas están dentro del script, no en
  `tests/` con `testthat`.
- `tidyr::pivot_wider` se usa sin cargar `tidyr` (líneas 247, 258 y 269). Funciona si
  está instalado, pero es una dependencia oculta.
- La lista `dimensiones` y los años están repetidos en otros scripts (líneas 182–184).

#### `04_estadistica_descriptiva.R`, etapa 4: descriptiva ponderada
- **Qué hace.**
  - Calcula medidas ponderadas (media, cuantiles, moda, DE, CV, asimetría, curtosis).
  - Arma frecuencias (ingreso agrupado en SMMLV), tablas cruzadas, correlaciones y la
    evolución 2018–2026.
  - Genera 6 figuras. Todas las estadísticas usan `fex_aj` como peso.
- **Error de comentario.** La línea 19 dice que la salida va a `resultados/descriptiva/`,
  pero en realidad va a `outputs/descriptiva/` (38–39).
- **Dependencia no declarada.** El boxplot ponderado (`aes(weight = w)`, líneas 349–355)
  necesita el paquete `quantreg`, que no figura en el README. Sin él la figura falla o
  sale sin ponderar.
- La tabla de SMMLV (50–54) está escrita en el código. Debe ir a la configuración, con
  su fuente (decretos).
- **Falta:** QQ-plot de ln(ingreso) y prueba complementaria sobre una submuestra. Las
  figuras están en PNG y deberían ir en PDF para LaTeX. Tampoco hay tablas `.tex`.
- La semilla (2026, línea 393) está escrita en el código.

#### Archivos sueltos
- `scripts/.Rhistory`, `.RData` y `.RDataTmp`: los ignora Git. Se pueden borrar
  localmente cuando quieras; no los toco.
- El README cita `03_ejemplo_theil.R` (línea 57), que **no existe**.

### 1.4 Rutas y constantes
- No hay `setwd()` ni rutas absolutas: todos los scripts usan `here()`. Bien.
- Constantes repetidas en varios scripts y que deben ir a `R/config.R`:

  | Constante | Dónde se repite |
  |---|---|
  | años 2018–2026 | 00:22, 01:26, 02:23, 03:182, 04:36 |
  | meses 1–6 | 01:27 |
  | 2020 excluido | 03:182, 04:36, 02:46 |
  | dimensiones | 02:43, 03:184, 04:323 |
  | edad mínima, mínimo por celda | 02:25–26 |
  | departamentos comunes | 02:36 |
  | SMMLV | 04:50 |
  | semilla | 04:393 |

### 1.5 Datos

| Carpeta | Archivos | Tamaño | > 50 MB | En Git |
|---|---|---|---|---|
| `data/raw/` | 710 .dta | 62.078 MB | 219 archivos | No (ignorada) |
| `data/final/*.rds` | 9 | 22 MB (máx. 2,9) | 0 | No (ignorados) |
| `data/analitica/*.rds` | 9 | 40 MB (máx. 5,2) | 0 | No (ignorados) |
| reportes, resultados, outputs | 76 CSV, 6 PNG | 2 MB | 0 | Sí |
| `docs/` | 2 PDF, 1 xlsx, .tex, .bib | 1,4 MB | 0 | Sí |

El `.gitignore` cubre `.dta`, `data/raw/`, los `.rds` intermedios, los archivos de
sesión de R, los auxiliares de LaTeX y los del sistema operativo.

### 1.6 Hallazgos que adelanto de las Fases 2 y 3 (se profundizan allá)

1. **No respuesta de ingreso anómala en 2018.** En la población de estudio no reporta
   ingreso el 13,1 % en 2018, frente a 3,4 % en 2019 y 0,4–4,9 % en el resto (sin 2020).
   El patrón es estable mes a mes y se concentra en Cabecera: 12–15 % frente a 3–4 % en
   Resto. Una diferencia así sugiere que la variable se construyó distinto ese año (por
   ejemplo, que el DANE no imputó el ingreso igual que en otros años). No parece un
   problema del código.
   - **Por qué importa.** `fex_aj` supone que, dentro de cada celda, quien no responde
     gana como quien sí responde. Con 13 % de no respuesta, ese supuesto pesa mucho más
     en 2018 que en 2026, y 2018 es justo el punto de partida de H3.
   - Hay que revisar si los archivos de 2018 traen una versión imputada del ingreso.
2. **H2 frente a los resultados actuales.** Con `fex_aj`, la participación "entre"
   (S) de 2026 es 35,0 % para estrato, 25,3 % para educación y 24,8 % para formalidad
   (`theil_resumen.csv`). La estimación puntual **contradice H2**: el estrato explica
   más que la educación. Esto se reporta tal cual; no se cambia la hipótesis.
   - Además, S tiende a crecer con el número de grupos: estrato tiene 6, educación 5 y
     sexo 2. Comparar S entre dimensiones con distinto número de categorías no es del
     todo justo. Lo anoto como decisión para el equipo.
3. **H3 tiene una diferencia pequeña y confundida.** T_A pasa de 0,4392 (2018) a 0,4288
   (2026), una diferencia de −0,010. Pero en medio hay un salto de 0,474 a 0,538 entre
   2021 y 2022, cuando cambian el marco y el factor, y además está la anomalía de 2018.

### 1.7 Lista priorizada de correcciones

**Críticas** (resultados posiblemente sesgados o ejecución rota)
1. La no respuesta de ingreso de 2018 (13 %) debe investigarse antes de usar 2018 en H3.
2. Un clon nuevo no puede correr `00`, `03` ni `04`, porque los `.rds` no se versionan.
   Se resuelve con `data/processed/*.csv.gz` (Fase 6).
3. `01_base_cruda_anual.R:711` ejecuta un diagnóstico que exige los datos de 2020.
4. No existen los estimadores C y D, la simulación, el bootstrap ni las pruebas: son el
   eje del proyecto.

**Importantes** (reproducibilidad, estructura, requisitos del curso)
5. Constantes repetidas → `R/config.R`. Funciones → `R/`.
6. Pruebas dentro de `03` → `tests/` con `testthat` y casos verificables a mano.
7. Dependencias no declaradas (`quantreg`, `tidyr`) y falta `renv`.
8. Las figuras en PNG y las tablas en CSV no entran a LaTeX con `\input{}` ni
   `\includegraphics{}`. Hay que pasar a PDF y `.tex` en `outputs/`.
9. README desactualizado (`03_ejemplo_theil.R`, `report/`, "ya están en el repositorio").
10. Falta el QQ-plot y la prueba de normalidad complementaria. Faltan procedimientos
    clásicos del curso (t, F, χ², IC clásico, regresión): ver la Fase 4.
11. Documentar el nivel N6 "resto" del ajuste y las celdas con menos de 30 respondientes.

**Cosméticas**
12. Comentarios desactualizados: 02:76, 02:109, 02:349 y 04:19.
13. "Orinoquía-Amazonía" en `niveles_region` sin uso en la serie común.
14. Archivos de sesión sueltos (`scripts/.Rhistory`, `.RDataTmp`).

---

## Decisiones para el equipo

Se van agregando a medida que avanza la auditoría. Ninguna se toma sin consultar.

| # | Decisión | Opciones | Origen |
|---|---|---|---|
| D1 | Estrato faltante (~3.500 respondientes por año, de menor ingreso) | (a) dejarlos fuera de todo (hoy); (b) categoría "Sin estrato"; (c) exigir estrato solo en su propia descomposición | ESTADO_PROYECTO, Fase 2 |
| D2 | C y D con pesos o sin pesos | (a) sin pesos (hoy implícito); (b) con pesos, lo que aísla el supuesto lognormal | ESTADO_PROYECTO, Fase 3 |
| D3 | Comparación de H3 | (a) 2018 vs 2026; (b) 2022 vs 2026 (mismo marco) como prueba principal y 2018 como referencia | ESTADO_PROYECTO |
| D4 | Ingresos muy bajos | regla de recorte, o solo análisis de sensibilidad | ESTADO_PROYECTO, Fase 2 |
| D5 | Diseño de muestreo de la simulación | se detalla en la Fase 3 | Fase 3 |
| D6 | Bootstrap por persona o por vivienda (`DIRECTORIO`) | | ESTADO_PROYECTO |
| D7 | Tratamiento de 2018 por la no respuesta del 13 % | depende de la Fase 2 | Fase 1, hallazgo 1 |
| D8 | Comparar S entre dimensiones con distinto número de grupos (H2) | (a) mantener S; (b) reportar además una medida que no dependa del número de grupos | Fase 1, hallazgo 2 |
