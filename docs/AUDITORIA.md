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

## Fase 2 — Auditoría de la limpieza de datos

Los diagnósticos se corrieron con scripts de solo lectura sobre los `.rds` de la corrida
anterior y sobre los `.dta` crudos. Al final de esta sección está la comparación con una
corrida nueva desde los `.dta`.

### Resumen

| # | Punto | ¿Implementado? | ¿Correcto? | Riesgo |
|---|---|---|---|---|
| 1 | Área descartada, Cabecera + Resto apilados | Sí | Sí | Ninguno |
| 2 | Llaves en módulos y uniones | Sí | Sí | Ninguno |
| 3 | Meses 1–6; 2020 fuera de los resultados | Sí | Sí | Ninguno |
| 4 | No respuesta y celdas de ajuste | Sí | Parcial | **Alto**: el ajuste no corrige la no respuesta por estrato |
| 5 | Ingresos cero o negativos | Sí | Sí, pero el texto lo justifica mal | Bajo |
| 6 | Atípicos y códigos de no respuesta | No hay regla | — | Medio, sobre todo para D |
| 7 | Cambio de FEX en 2022 | Documentado, sin corrección | — | **Alto** para H3 |
| 8 | Estrato faltante | Excluidos de todo | Decisión abierta | Medio para H3 |
| 9 | Bases anuales idénticas en estructura | Sí | Sí | Ninguno |
| 10 | Números de la entrega | — | Coinciden todos | Ninguno |
| — | **Nuevo: código 7 de `P6430` desde 2022** | — | **Error** | **Medio**: excluye ~3.400 trabajadores pagados por año |

### 2.1 Área, Cabecera y Resto (2018, 2019 y 2021)

`01_base_cruda_anual.R:345–404` lee los tres archivos, verifica que Área esté contenida
en Cabecera y apila Cabecera + Resto. Totales del módulo Ocupados, meses 1–6:

| Año | Área n | Cabecera n | Resto n | Final n | Final − (Cab + Resto) | FEX Cab + Resto | FEX final |
|---|---|---|---|---|---|---|---|
| 2018 | 85.796 | 157.586 | 17.082 | 174.668 | 0 | 133.260.489 | 133.260.489 |
| 2019 | 83.699 | 152.676 | 15.765 | 168.441 | 0 | 132.513.424 | 132.513.424 |
| 2021 | 72.353 | 131.874 | 14.220 | 146.094 | 0 | 123.147.371 | 123.147.371 |

Enero de 2018: Cabecera 24.952 + Resto 2.741 = **27.693**. Coincide con la entrega.
Los mensajes "Invalid timestamp string" que imprime `haven` vienen de la fecha de
creación del archivo del DANE y no afectan los datos.

### 2.2 Llaves

En los nueve años hay 0 duplicados de (MES, DIRECTORIO, SECUENCIA_P, HOGAR, ORDEN),
0 llaves vacías, 0 ocupados sin pareja en cada módulo y 0 diferencias de FEX o DPTO
entre módulos. Las líneas 337, 429, 471, 512–514 y 633 del script de la etapa 1 detienen
la ejecución si algo de esto falla.

Solo en 2020 hay 120 llaves repetidas entre meses: son hogares encuestados dos veces en
la recolección telefónica. No afecta, porque 2020 no se usa.

### 2.3 Meses y 2020

Todas las bases tienen exactamente los meses 1 a 6 (entre 21.605 y 32.979 ocupados por
mes). `theil_resumen.csv` contiene solo 2018, 2019 y 2021–2026. 2020 no entra a ningún
resultado: lo excluyen `03_theil.R:182` y `04_estadistica_descriptiva.R:36`.

### 2.4 No respuesta de ingreso

**Cómo se maneja.** No hay `na.omit` ni `drop_na`. El ingreso faltante marca
`responde = FALSE` (`02:368`); la persona sigue en la población y su peso se reparte
dentro de su celda (`02:189–266`). Las demás dimensiones casi no tienen faltantes, salvo
el estrato:

| Año | n (antes de exigir dimensiones) | % NA ingreso | % NA educ | % NA estrato |
|---|---|---|---|---|
| 2018 | 165.975 | **12,94** | 0,01 | 2,20 |
| 2019 | 159.923 | 3,37 | 0,01 | 2,06 |
| 2021 | 138.916 | 4,88 | 0,01 | 1,75 |
| 2022 | 173.101 | 4,30 | 0,00 | 2,79 |
| 2023 | 164.242 | 1,55 | 0,00 | 2,40 |
| 2024 | 159.750 | 2,43 | 0,00 | 2,31 |
| 2025 | 158.359 | 0,84 | 0,00 | 2,34 |
| 2026 | 159.642 | 0,38 | 0,00 | 2,74 |

Formalidad, sexo, región y posición tienen 0 % de NA. En 2020, el 57 % no tiene ingreso
y el 100 % no tiene estrato.

**2018 no es un error del código.** Los archivos de 2018 y 2019 tienen exactamente las
mismas columnas. En quienes no tienen `INGLABO` tampoco hay salario (`P6500`) ni ganancia
(`P6750`), así que no hay de dónde recuperar el dato. El 13 % es no respuesta real en los
microdatos de ese año.

**La no respuesta crece con el estrato, y el estrato no está en las celdas.** Este es el
hallazgo más importante de esta fase. Porcentaje que no reporta ingreso, por estrato:

| Estrato | 2018 | 2019 | 2021 | 2022 | 2024 | 2026 |
|---|---|---|---|---|---|---|
| 1 | 12,7 | 2,1 | 2,3 | 2,5 | 1,2 | 0,1 |
| 3 | 15,2 | 4,5 | 7,1 | 5,6 | 3,0 | 0,5 |
| 5 | 26,6 | 11,3 | 18,7 | 12,8 | 7,6 | 1,8 |
| 6 | 27,0 | 12,6 | 22,0 | 17,0 | 12,5 | 1,8 |

El mismo gradiente aparece con educación superior, patrones y empleados del gobierno.
Esas tres variables sí están en las celdas, el estrato no
(`02_base_analitica_anual.R:57–63`).

- **Por qué es un problema.** Dentro de una celda (por ejemplo "Asalariado | Formal |
  Superior | Bogotá | Hombre"), quienes no responden viven en estratos más altos que
  quienes responden. Al repartir su peso entre los respondientes, la población ajustada
  queda con menos estrato 5–6 del que tiene en realidad:
  - 2018: 2,23 % en lugar de 2,53 %.
  - 2021: 2,19 % en lugar de 2,54 %.
  - Pierde justo la cola alta del ingreso, y por eso **el Theil A queda subestimado**.
- **Prueba de sensibilidad** (no cambia el pipeline). Se reescala `fex_aj` para que
  cada estrato conserve su total de FEX:

  | Año | T_A actual | T_A respetando el estrato | Diferencia |
  |---|---|---|---|
  | 2018 | 0,4392 | 0,4493 | **+0,0101** |
  | 2021 | 0,4739 | 0,4883 | **+0,0144** |
  | 2022 | 0,5381 | 0,5451 | +0,0070 |
  | 2024 | 0,5043 | 0,5114 | +0,0071 |
  | 2026 | 0,4288 | 0,4305 | +0,0017 |

- **Qué le hace a H3.** El sesgo es mayor en 2018 que en 2026 porque la no respuesta
  cayó de 13 % a 0,4 %. Con la corrección, la caída 2018→2026 pasa de −0,010 a −0,019.
  Ni el signo ni la decisión de H3 son robustos a cómo se trate la no respuesta
  (ver 2.8). Es la decisión **D9**.
- Aun corrigiendo por estrato queda un supuesto que los datos no pueden verificar: que,
  dentro de la celda, quien no responde gana como quien responde.

**Celdas.**
- Entre 25 y 35 celdas por año tienen entre 30 y 39 respondientes, justo encima del
  mínimo.
- Hay celdas con menos de 30 en 2019 (20 respondientes), 2022 (6) y 2025 (24). En los
  tres casos es la celda de respaldo "N6 | resto", que mezcla posiciones (`02:214`).
  Afecta a 6–24 filas.
- **Pesos extremos.** El factor de ajuste máximo es 2,17 (2018 y 2021) y 1,20 en 2026.
  El mayor `fex_aj` es entre 36 y 62 veces la mediana, igual que el FEX original:
  el ajuste no crea pesos extremos nuevos.
- **Tamaño efectivo de Kish** (≈ 52.000 de ≈ 150.000 respondientes): los pesos
  multiplican la varianza por cerca de 3. Esto importa para el bootstrap y para la
  simulación.

### 2.5 Ingreso cero o negativo

| Año | Con ingreso 0 | Negativos | % cero |
|---|---|---|---|
| 2018 | 2.419 | 0 | 1,69 |
| 2022 | 2.417 | 0 | 1,48 |
| 2026 | 1.161 | 0 | 0,75 |

- **Tratamiento.** El cero queda fuera de la población (`f_no_cero`, `02:365`). No se
  trata como no respuesta. Es idéntico para los cuatro estimadores, porque los cuatro
  usan la misma base filtrada.
- **El texto de la entrega lo justifica mal.** Dice que "el Theil … usa logaritmos y
  ln 0 no está definido". Para el Theil T (A y B) eso no es cierto: el término de una
  persona con y = 0 es (0/μ)·ln(0/μ), cuyo límite es 0. A, B y C pueden calcularse con
  ceros; solo D (ln y) los necesita fuera.
  - La exclusión sigue siendo defendible: así los cuatro estimadores comparan la misma
    población. Pero esa es la razón que debe ir en el texto.
  - Además, excluir los ceros reduce la desigualdad medida.
- Los ceros bajan de 1,7 % a 0,75 %. La exclusión también afecta un poco la comparación
  de H3.

### 2.6 Atípicos y códigos

- No hay códigos 98/99/999999 en las dimensiones: `02` los deja en NA (estrato 0/9 en
  `02:330`; educación 9 y 99 quedan sin equivalencia).
- **Ingreso muy bajo** (respondientes de la población):

  | Año | Mínimo | p0,1 | p1 | Mediana | p99 | p99,9 | Máximo | < $50.000 | = 98, 99, 999… |
  |---|---|---|---|---|---|---|---|---|---|
  | 2018 | 12 | 12.000 | 40.000 | 781.242 | 5,3 M | 15 M | 102 M | 1.497 | 16 |
  | 2021 | 1 | 12.000 | 40.000 | 900.000 | 6,0 M | 15 M | 100 M | 1.385 | 2 |
  | 2026 | 1 | 30.000 | 100.000 | 1.750.000 | 12 M | 30 M | 108 M | 389 | 0 |

- **Por qué importa.** Un ingreso de $1 tiene ln y = 0, a unas 14 unidades de la
  mediana en logaritmos. En D (la varianza de ln y), una sola observación así pesa como
  miles de observaciones normales. A y B casi no se mueven, porque usan y/μ y no ln y.
  Esto puede hacer que D "pierda" en la simulación por la cola baja y no por el supuesto
  lognormal. Es la decisión **D4**: una regla de recorte o, al menos, un análisis de
  sensibilidad.
- Los 16 valores de 2018 iguales a 98, 99, 999… pueden ser códigos de "no sabe" que se
  colaron. Hay que revisarlos.
- **Horas.** `P6800` va de 1 a 130, y entre 169 y 444 personas por año reportan más de
  100 horas semanales. Solo afecta la descriptiva.

### 2.7 Cambio del factor de expansión en 2022

`01:90` toma `fex_c_2011` en 2018–2021 y `FEX_C18` en 2022–2026, como se decidió. El
código no corrige ni armoniza el cambio.

| Año | Fuente | Ocupados/mes (millones) | CV del FEX | T_A | T_B |
|---|---|---|---|---|---|
| 2019 | FEX_C_2011 | 22,09 | 1,34 | 0,4772 | 0,4126 |
| 2021 | FEX_C_2011 | 20,52 | 1,33 | 0,4739 | 0,4150 |
| 2022 | FEX_C18 | 21,70 | 1,44 | 0,5381 | 0,4536 |
| 2026 | FEX_C18 | 24,17 | 1,40 | 0,4288 | 0,3921 |

- **El salto de 2021 a 2022 no es solo de pesos.** También T_B, que no usa pesos, sube
  de 0,415 a 0,454. Cambiaron a la vez el marco muestral, el cuestionario (códigos de
  educación, posición y tamaño de empresa) y el factor.
- **Riesgo para H3.** 2018 y 2026 están en marcos distintos, y no se puede separar el
  cambio real del cambio metodológico. Es la decisión **D3** (2022 vs 2026 como prueba
  principal).
- El DANE publicó retroproyecciones de factores con el marco 2018 para años anteriores.
  Si existen para 2018–2021, permitirían una prueba de sensibilidad. Hay que verificarlo
  en el portal de microdatos; no lo he comprobado.

### 2.8 Estrato faltante

Respondientes con todo completo menos el estrato, con pesos FEX:

| Año | n sin estrato | % del FEX | Ingreso medio vs. resto | T sin ellos | T con ellos | Diferencia |
|---|---|---|---|---|---|---|
| 2018 | 3.460 | 3,75 | 0,56 | 0,4322 | 0,4354 | +0,0032 |
| 2021 | 2.378 | 3,16 | 0,56 | 0,4622 | 0,4625 | +0,0003 |
| 2022 | 4.706 | 3,54 | 0,39 | 0,5314 | 0,5378 | +0,0064 |
| 2024 | 3.656 | 3,04 | 0,41 | 0,4981 | 0,5044 | +0,0063 |
| 2026 | 4.371 | 3,88 | 0,41 | 0,4279 | 0,4354 | +0,0075 |

- En 2024 son 2.446 personas con código 0, 784 con código 9 y 548 vacías. El resultado
  confirma el de `ESTADO_PROYECTO.md` (2024: 0,498 → 0,504).
- **Qué le hace a H3.** Con FEX, la caída 2018→2026 es −0,0043 sin ellos y **0,0000**
  con ellos. Es la decisión **D1**.

**Sensibilidad de H3 en conjunto.** T₂₀₂₆ − T₂₀₁₈ según cada decisión de limpieza:

| Variante | Diferencia |
|---|---|
| Actual (`fex_aj`) | −0,0104 |
| `FEX` sin ajuste | −0,0043 |
| `FEX` + incluir a quienes no tienen estrato | 0,0000 |
| `FEX` + incluir el código 7 (2.9) | −0,0070 |
| `fex_aj` respetando el estrato | −0,0188 |

H3 depende de las decisiones de limpieza tanto como de los datos. El informe debería
mostrar esta tabla.

### 2.9 Nuevo: código 7 de `P6430` desde 2022 (error)

`02_base_analitica_anual.R:343` clasifica `P6430 %in% c(6, 7)` como "Sin
remuneración", y `f_remunerado` los excluye. Eso coincide con el diccionario del DANE de
ambos marcos ("7 = Trabajador sin remuneración en empresas de otros hogares"). Pero
**los datos de 2022–2026 no se comportan así**:

| `P6430` (2024) | n | Con ingreso > 0 | Ingreso mediano |
|---|---|---|---|
| 6 | 3.048 | 0 | — |
| 7 | 4.193 | **4.153** | **1.000.000** |
| 8 | 70 | 66 | 300.000 |
| 9 | 0 | — | — |

En 2019, en cambio, el código 7 tiene 502 personas y ninguna con ingreso, y el 8
(jornalero) tiene 2.240. Desde 2022 el código 7 es 70 % rural y casi siempre pagado: se
comporta como "jornalero o peón", y el 8 como "otro". Todo indica que en los archivos
del marco 2018 los códigos 7–9 se corrieron. El comentario de `02:334` ("el marco 2018
casi no usa el código 8") era la pista.

- **Efecto.** Entre 3.262 y 3.670 trabajadores pagados por año (≈ 3 % del FEX) quedan
  fuera en 2022–2026. Su ingreso es medio-bajo, así que excluirlos sube el Theil A en
  unos +0,003 por año: con FEX, 2024 pasa de 0,4981 a 0,4947 si se incluyen. Además, el
  "Otro" de 2022 en adelante (código 8) termina como "Asalariado privado".
- **Corrección propuesta (Fase 5, con tu aprobación).** Recodificar `P6430` según el
  marco (`EDUC_FUENTE` ya distingue los marcos), después de confirmar con el formulario
  del DANE. Toca el núcleo de la limpieza; no lo aplico sin permiso.

### 2.10 Estructura de las bases finales

Los nueve `analitica_<año>.rds` tienen las mismas 30 columnas, en el mismo orden, con
los mismos tipos y los mismos niveles en los factores. `region` conserva el nivel
"Orinoquía-Amazonía", que en la cobertura común está vacío.

### 2.11 Números de referencia

Coinciden **todos** los números de la entrega vigente (`primera_entrega_corregida.tex`,
Tabla 2):

| Año | Ocupados | Población de estudio | Entran al Theil | % FEX | Coincide |
|---|---|---|---|---|---|
| 2018 | 174.668 | 162.300 | 141.025 | 82,6 | Sí |
| 2019 | 168.441 | 156.616 | 151.283 | 87,6 | Sí |
| 2020 | 146.862 | 96.931 | 57.042 | 46,4 | Sí |
| 2021 | 146.094 | 136.479 | 129.750 | 86,2 | Sí |
| 2022 | 194.647 | 168.270 | 160.946 | 85,3 | Sí |
| 2023 | 183.136 | 160.299 | 157.776 | 88,3 | Sí |
| 2024 | 178.204 | 156.063 | 152.213 | 86,9 | Sí |
| 2025 | 176.176 | 154.659 | 153.340 | 89,1 | Sí |
| 2026 | 177.195 | 155.262 | 154.657 | 89,0 | Sí |

También coinciden: 27.693 ocupados en enero de 2018, 24 departamentos, 5 regiones y
"más de 140.000 ocupados" por año (sin contar 2020 y 2021, que tienen 129.750).

La entrega todavía no reporta Theil ni participaciones "entre". Los valores actuales
están en `data/resultados/theil_resumen.csv` y en `CLAUDE.md` §9.

**Qué habría que actualizar en el texto** (propuestas; no edito la entrega):
1. "Más de 140.000 ocupados" es falso para 2021 (129.750 entran al Theil). Sugerencia:
   "entre 130.000 y 160.000".
2. "Ingreso positivo: … el Theil … usa logaritmos" debe reformularse (ver 2.5).
3. "Remunerados" debe mencionar la recodificación de `P6430` si se aprueba la
   corrección de 2.9. Si se aprueba, cambian todos los números de 2022–2026 de la
   Tabla 2.

**Corrida nueva desde los .dta** (28-10-2026, R 4.5.2). `01`, `02` y `03` se corrieron
completos: 4,2 + 0,4 + 0,2 = 4,8 minutos. Contra la corrida anterior:
- los 18 `.rds` son **idénticos** (`all.equal` con tolerancia 0);
- `theil_resumen.csv` y `theil_grupos.csv` son idénticos;
- Git no muestra cambios en ningún reporte versionado.

Las únicas advertencias de la corrida son que `here` se compiló con R 4.5.3 y que
`P6210 = 9` ("no sabe") queda en NA para 2 a 21 personas por año. El pipeline es
reproducible.

---

## Fase 3 — Función de Theil, estimadores y diseño del Monte Carlo

### 3.1 Código frente a las fórmulas

| Estimador | Fórmula de la propuesta | Código antes de esta fase | Diferencia |
|---|---|---|---|
| A | (1/W) Σ wᵢ (yᵢ/μ) ln(yᵢ/μ), μ ponderada | `theil_decomp(y, fex_aj)` | Ninguna |
| B | Igual que A con wᵢ = 1 | `theil_decomp(y)` | Ninguna |
| C | σ² = ln(1 + CV²), T = σ²/2 | **No existía** | — |
| D | σ² = (1/n) Σ (ln yᵢ − m)², T = σ²/2 | **No existía** | — |
| Descomposición | between = Σ sₖ ln(μₖ/μ); within = Σ sₖ Tₖ, con sₖ = participación en el ingreso | `theil_decomp(..., g)` | Ninguna. Además verifica T = T_B + T_W |

**Cambios de esta fase (sin commit, para revisión de Gabriel):**
- `R/theil.R` (nuevo):
  - `theil_decomp()`, copiada **sin cambios** desde `03_theil.R`.
  - `theil_A()` y `theil_B()`, envoltorios de una línea.
  - `theil_C()` y `theil_D()`, nuevos.
- `scripts/03_theil.R`: borra la definición de la función y la reemplaza por
  `source(here("R", "theil.R"))`. Se volvió a correr y `theil_resumen.csv` y
  `theil_grupos.csv` no cambiaron.

**Detalles de C y D:**
- **D divide por n, no por n − 1.** El EMV de σ² divide por n, y `var()` de R divide
  por n − 1. Con n = 500 la diferencia es D/(n − 1) ≈ 0,0008 (en una submuestra de
  2024: 0,38149 contra 0,38225).
  - Frente a la desviación estándar de D en n = 500 (0,039) es pequeña.
  - Pero no es ruido: es un sesgo sistemático, y el error estándar del promedio de 500
    réplicas es 0,0018, del mismo orden. Con `var()`, la simulación podría atribuirle
    a D un sesgo que viene de la fórmula y no del supuesto lognormal.
  - Por eso `theil_D()` divide por n, y un test lo verifica.
- **C también divide por n.** El método de momentos iguala los momentos *muestrales*,
  que dividen por n. La propuesta escribe s²_y, que muchos leen como dividido por n − 1.
  Conviene aclararlo en el texto.
- **C y D aceptan pesos opcionales** (`w = NULL` por defecto, como en la propuesta).
  Cuál variante se usa en la simulación lo decide el equipo (D2). Ver el efecto en 3.4.
- **NA, ceros y pesos.** Las cuatro funciones se detienen si hay NA, ingresos ≤ 0,
  pesos negativos, pesos que suman 0 o longitudes distintas. Un peso igual a 0 está
  permitido y equivale a no incluir a esa persona (hay un test). `n` cuenta también a
  las personas con peso 0; hoy no ocurre, porque `03` filtra por `responde`.

### 3.2 Pruebas (`tests/testthat/`)

Se corren con `testthat::test_dir("tests/testthat")` desde la raíz del proyecto.
Resultado: **186 comprobaciones, 0 fallas**.

| Prueba | Resultado esperado a mano |
|---|---|
| Ingresos iguales | T = 0 en A, B, C y D |
| Una persona con todo el ingreso (n = 2, 10, 1.000) | T = ln n. Los demás reciben 10⁻¹², porque la función exige y > 0 |
| Ejemplos 1 y 2 (antes en `03_theil.R`) | T, T_B y T_W calculados a mano |
| Dos personas con ingresos 1 y 3 | ½[½ ln ½ + 1,5 ln 1,5] |
| Escala: ingresos × 0,001 y × 10⁶; pesos × c | Ningún estimador cambia |
| A con pesos = 1 | Igual a B |
| A con pesos enteros | Igual a B con filas repetidas. Lo mismo para C y D con pesos |
| Descomposición simulada | T_B + T_W = T; T_W = Σ sₖTₖ; Σ sₖ = 1; Tₖ = Theil del grupo calculado aparte |
| Un solo grupo | between = 0 |
| Lognormal con σ = 0,5 y 1 (n = 10⁶) | C, D y B se acercan a σ²/2 |
| D frente a `var()` | D usa el divisor n |
| NA, 0, negativos, pesos inválidos | Error en las cuatro funciones |
| Peso 0 | No cambia el resultado |
| **Datos reales**: 8 años × 5 dimensiones con `fex_aj` | T_B + T_W = T y T_W = Σ sₖTₖ (tolerancia 10⁻¹⁰). Se salta si no están las bases |

No se hizo la comparación con un paquete externo: `ineq` y `dineq` no están instalados
y solo se autorizó `testthat`. Los ejemplos calculados a mano cumplen ese papel. Si
quieren la comparación, hay que autorizar `ineq`.

### 3.3 Estado del Monte Carlo

**No existe.** No hay código de simulación, ni semilla, ni réplicas, ni grilla de n,
ni cálculo de sesgo, varianza, ECM o eficiencia relativa. Tampoco existen el bootstrap
ni las pruebas de H1, H2 y H3. Hoy el proyecto solo tiene el Theil A y B anual y la
descomposición.

Lo que la propuesta fija y debe ir a `R/config.R` cuando se programe:
- base 2024 completa;
- 500 réplicas;
- n ∈ {500, 2.000, 10.000, 50.000};
- semilla fija;
- métricas: sesgo, varianza, ECM y ER = ECM(A)/ECM(otro). Con ER < 1, A es mejor.

### 3.4 El diseño de submuestreo decide qué gana

Cuando n crece, cada estimador converge a su propio valor calculado sobre la
"población" que representan las submuestras. Ese valor depende de **cómo** se sacan
las submuestras.

Los límites para la base 2024 (N = 152.213 respondientes) se pueden calcular sin
simular, porque son el estimador sobre la población que las submuestras representan:

| Estimador | Límite si se muestrea uniforme entre encuestados | Sesgo | Límite si se muestrea con prob. ∝ `fex_aj` | Sesgo |
|---|---|---|---|---|
| **Verdad** (A sobre la base completa) | 0,5043 | — | 0,5043 | — |
| A (pesa con `fex_aj`) | 0,5043 | **0,000** | 0,5559 | +0,052 |
| B | 0,4273 | −0,077 | 0,5043 | **0,000** |
| C sin pesos | 0,5280 | +0,024 | 0,5921 | +0,088 |
| C con pesos | 0,5921 | +0,088 | 0,6136 | +0,109 |
| D sin pesos | 0,4264 | −0,078 | 0,4821 | −0,022 |
| D con pesos | 0,4821 | −0,022 | 0,5149 | +0,011 |

Qué se lee en la tabla:

1. **Circularidad con muestreo uniforme.** Si la submuestra se saca uniformemente entre
   los encuestados y la "verdad" es A sobre la base completa, A es insesgado *por
   construcción*: con n = N, A reproduce exactamente la verdad.
   - Con ese diseño, H1 solo prueba que "A converge a A". El sesgo de B (−0,077) es la
     distancia entre el promedio ponderado y el no ponderado de la base.
   - Eso sí es informativo: mide cuánto importan los pesos en la GEIH. Pero no es una
     validación independiente de A.
2. **Con probabilidad ∝ peso, el resultado se invierte.** La submuestra se "autopondera"
   y ya representa a Colombia. B es insesgado, y A, que vuelve a aplicar los pesos,
   cuenta los pesos dos veces y queda sesgado (+0,052). Este diseño prueba lo
   contrario de H1 y no es una comparación justa para A.
3. **C sin pesos "gana" por casualidad.** Con muestreo uniforme, C sin pesos tiene el
   menor sesgo después de A (+0,024). Pero es por compensación de errores:
   - no usar pesos baja el valor;
   - la cola pesada, que no es lognormal, lo sube.
   - Con pesos, C se aleja (+0,088).
   - Por eso es importante la decisión D2: **sin pesos, la comparación de A contra C y D
     mezcla dos problemas (diseño muestral y supuesto lognormal) que pueden cancelarse.**
     Con pesos, C y D se comparan con A solo en el supuesto lognormal, y B ya cubre el
     problema de los pesos.
4. **D depende de la cola baja.** Al quitar los 665 ingresos menores de $50.000 (0,4 %
   de los respondientes), D sin pesos pasa de 0,426 a 0,395, mientras que A solo pasa de
   0,504 a 0,499 (decisión D4, Fase 2 §2.6).

**Con o sin reemplazo.** Con n = 50.000 se toma el 32,8 % de la base.
- **Sin reemplazo,** la varianza se multiplica por el factor de población finita
  (1 − n/N) = 0,67. El ECM de n = 50.000 baja más de lo que bajaría en una población
  grande, y la "consistencia" se ve más rápida de lo que es. En el límite n = N, la
  varianza es 0.
- **Con reemplazo,** cada réplica imita una muestra de una población infinita con la
  distribución de la base. La varianza sigue la regla 1/n, y n = 50.000 no tiene nada
  de especial.
- En n = 500 y n = 2.000 la diferencia es despreciable: el factor es 0,997 y 0,987.

### 3.5 Opciones de diseño (no elijo; es la decisión D5)

| Opción | Cómo se hace | Verdad | Qué prueba | Qué no prueba | Costo |
|---|---|---|---|---|---|
| **O1. Muestreo uniforme de encuestados, sin reemplazo** (lo que sugiere la propuesta) | `sample(N, n)`. Cada persona lleva su `fex_aj` | A sobre la base 2024 | Cuánto se equivoca B por ignorar los pesos. Compara C y D con A | A no tiene competencia real (circular). La FPC exagera la consistencia en n = 50.000 | Mínimo |
| **O2. Como O1, con reemplazo** | `sample(N, n, replace = TRUE)` | Igual | Lo mismo que O1, con varianza que sigue 1/n | Sigue siendo circular para A | Mínimo |
| **O3. Probabilidad ∝ `fex_aj`, con reemplazo** | `sample(N, n, TRUE, prob = fex_aj)` | A sobre la base 2024 | Compara C y D contra B en una muestra autoponderada: aísla el supuesto lognormal | No sirve para A: aplicarle pesos a una muestra autoponderada lo sesga | Mínimo |
| **O4. Pseudopoblación + muestreo desigual** | (i) Expandir cada respondiente unas `fex_aj / k` veces (con k ≈ 10, unos 2–3 millones de filas). (ii) Muestrear con prob. ∝ 1/`fex_aj`, como la GEIH, y darle a cada unidad el peso 1/π | El Theil de la pseudopoblación: un parámetro poblacional, no la salida de un estimador | Es la versión no circular de H1. A (Horvitz–Thompson/Hájek) debería ser consistente y B sesgado por diseño; C y D fallan solo por el supuesto lognormal | Ignora conglomerados y estratos de la GEIH. Redondear `fex_aj / k` introduce un pequeño error | Moderado (memoria y algo más de código) |

Qué conviene decidir junto con D5:
- Si se elige O1 u O2, el informe debe decir explícitamente que el sesgo de A es 0 por
  construcción, y presentar el resultado de B como "el costo de ignorar los pesos".
- La semilla, las réplicas y la grilla de n van a `R/config.R`. Junto a cada sesgo y
  ECM hay que reportar el error estándar Monte Carlo (DE/√500). Si no, no se sabe si
  una diferencia entre estimadores es real o es ruido de la simulación.
- **Sobre la prueba t de H1.** Las réplicas son independientes, así que la prueba t
  pareada es válida. Pero su potencia la fija el equipo al elegir R, no los datos: con
  R suficientemente grande, cualquier diferencia de ECM sale significativa. Conviene
  reportar primero la ER y el tamaño de la diferencia, y después el valor p.
- **Bootstrap (D6).** El n efectivo de Kish es ≈ 52.000 de 152.000. Un bootstrap por
  persona sin respetar los pesos ni las viviendas va a dar intervalos demasiado
  estrechos.

---

## Fase 4 — Estadística descriptiva y alineación con el curso

El checklist completo está en `docs/requisitos.md`. La tabla por sesión y las propuestas
están en `docs/alineacion_curso.md`.

### 4.1 Descriptiva frente a la guía

| Pide la guía | `04_estadistica_descriptiva.R` | Comentario |
|---|---|---|
| Tipo y escala de cada variable | `diccionario_variables.csv`, `data/codebook.md` | Bien |
| Frecuencias y gráficas univariadas | Tablas 02 (ingreso en SMMLV, edad y horas agrupadas) y 03 (cualitativas, muestra frente a población); figuras 03 (barras) y 07a (histograma) | Falta `tam_empresa`. Las clases de ingreso en salarios mínimos son una buena decisión y está justificada (`04:210–213`) |
| Tablas cruzadas y bivariadas | 4 tablas cruzadas (% por fila), ingreso por grupo, boxplots y dispersión horas–ingreso | Bien |
| Centro, posición, dispersión y forma | Tabla 01: media, mediana, moda, p10–p90, rango, RIC, DE, CV, asimetría y curtosis en exceso | Bien. La moda del ingreso en SMMLV depende de qué salario mínimo se use en enero (`04:177`) |
| Interpretación de cada tabla y figura | No existe | Va en el texto. Hoy ninguna entrega incluye la descriptiva |

**¿Está ponderada?** Sí. Todas las medidas, frecuencias y figuras usan `fex_aj`
(`04:176`). En la dispersión se usa una submuestra de 4.000 sacada con probabilidad ∝ peso.
Lo comprobé con un ejemplo de juguete:
- el boxplot pondera: con peso 1.000 en un valor, la mediana pasa a ese valor;
- el histograma también pondera.

El texto debe decir explícitamente que las cifras describen a la población de ocupados y
no a los encuestados.

**Advertencia de `ggplot2`.** "Weight dropped" sale de la figura `07b`
(`04:466–468`). La curva `stat_function` hereda `weight` y lo descarta; el histograma de
esa figura sí pondera. Es cosmético y se corrige con `inherit.aes = FALSE` en
`stat_function` (Fase 5).

**Otros detalles:**
- `06_evolucion.csv` llama "ocupados_millones" a la suma de `fex_aj` / 6 de la *población
  de estudio* (20,2 M en 2018), no al total de ocupados (22,2 M). Conviene renombrarla.
- Los CSV se escriben en UTF-8 sin BOM. Excel en Windows muestra mal las tildes
  ("BogotÃ¡"); R y LaTeX los leen bien. Si alguien los abre en Excel, sirve
  `write.csv(..., fileEncoding = "UTF-8-BOM")`.
- Las figuras son PNG y las tablas CSV. Para el informe deben salir en PDF y en `.tex`
  hacia `outputs/` (Fase 6/7).

### 4.2 Lognormalidad de ln(ingreso), 2024

Diagnóstico de solo lectura: submuestra de 5.000 con probabilidad ∝ `fex_aj`, semilla 2024.

| Medida | Valor | Normal |
|---|---|---|
| Asimetría ponderada | −0,52 | 0 |
| Curtosis en exceso | 2,30 | 0 |
| P(\|z\| > 3) | 1,11 % | 0,27 % |
| P(\|z\| > 4) | 0,19 % | 0,01 % |
| Ingreso exactamente igual a 1 SMMLV | 15,4 % | 0 (distribución continua) |
| Shapiro-Wilk, n = 5.000 | W = 0,954, p < 10⁻¹⁵ | — |
| Shapiro-Wilk, n = 200 (200 submuestras) | rechaza en el 100 % | 5 % si fuera normal |

- **El QQ-plot** muestra una cola baja mucho más larga que la normal (ingresos muy bajos),
  una cola alta más pesada y un escalón en el salario mínimo.
- **El rechazo no es solo un efecto de n grande:** aun con n = 200 se rechaza siempre.
- **Qué significa para el proyecto.** C y D suponen que ln y es normal. Con este nivel de
  desviación, se espera que converjan a un valor distinto del Theil, como ya mostró la
  Fase 3: C +0,024 a +0,088 y D −0,022 a −0,078 según el diseño.
- **Qué falta en `04`.** La figura 07b tiene el histograma con la curva normal, pero
  falta el QQ-plot y la prueba sobre una submuestra (propuesta P7). No se agregó: es una
  decisión de contenido.

### 4.3 Brechas principales frente al curso

1. **No hay ningún intervalo de confianza ni ninguna prueba de hipótesis implementados.**
   Es requisito mínimo del corte 3.
2. **No hay procedimientos clásicos (z, t, F, χ²) sobre los datos.** La t pareada de H1 es
   sobre réplicas simuladas.
3. **No hay regresión simple** (sesiones 26–27).
4. **Formato del informe:** la entrega usa Latin Modern e interlineado doble. La guía pide
   Times o Arial 12 e interlineado 1,5.
5. **La descriptiva no aparece interpretada en ninguna entrega.** Era del corte 2.

Las propuestas P1–P7 para cerrar 1 a 3 están en `docs/alineacion_curso.md` §2, y esperan
aprobación del equipo.

---

## Fase 5 — Correcciones aplicadas (28-10-2026)

Solo correcciones que no cambian decisiones metodológicas, más los análisis P1–P7
aprobados por Gabriel. Las decisiones D1–D10 siguen abiertas: ninguna se aplicó.

| Corrección | Archivos | Prioridad (§1.7) | ¿Cambia resultados? |
|---|---|---|---|
| Inferencia clásica P1–P7: IC t y z, t de Welch, F + Brown-Forsythe, χ² + V de Cramér, regresión simple con supuestos, Shapiro + QQ-plot | `scripts/05_inferencia_clasica.R` (nuevo), `run_all.R` | Crítica (corte 3) | Agrega `outputs/inferencia/` |
| Las constantes pasan a `R/config.R`: años, meses, años nacionales, edad mínima, departamentos comunes, mínimo por celda, dimensiones, SMMLV, años de referencia, semillas y parámetros de la inferencia | `R/config.R`, `01`, `02`, `04` | Importante | No |
| Se quita el diagnóstico `inventario(2020, …)`, que corría siempre, y el bloque de prueba comentado | `01_base_cruda_anual.R` | Crítica | No |
| Validaciones antes de guardar cada base: sin duplicados, FEX > 0, ingreso > 0 en respondientes, `fex_aj` solo en la población, no negativo, 0 en no respondientes y con el total conservado, edad y departamentos válidos | `02_base_analitica_anual.R` | Importante | No (todas pasan) |
| Comentarios "PENDIENTE" cerrados con las etiquetas del DANE (`P6210` 9 = no sabe; rangos de `P6870`); "PROPUESTA DE REGLA" pasa a "Regla decidida"; aviso de D10 junto al código de `P6430` | `02_base_analitica_anual.R` | Cosmética | No |
| `stat_function(inherit.aes = FALSE)` en la figura 07b: elimina la advertencia de `ggplot2` | `04_estadistica_descriptiva.R` | Cosmética | No (la figura es idéntica) |
| La columna `ocupados_millones` pasa a `poblacion_estudio_millones` | `04`, `06_evolucion.csv` | Cosmética | Solo el encabezado |
| Las bases se leen de `data/processed/` con `cargar_analitica()`; checksums MD5 | `R/datos.R`, `00`, `03`, `04`, `02b` | Crítica (clon nuevo) | No |

**Verificación.** Corrida completa desde los `.dta` con `run_all.R` (`desde_crudos <- TRUE`),
en 12,6 minutos:
- `01` tardó 4,9 min, `02` 0,7, `02b` 2,4, `00` 0,7, `03` 0,7, `04` 1,3 y `05` 0,7;
- 199 pruebas pasan, 0 fallan;
- los `data/processed/*.csv.gz` y `checksums.txt` son idénticos byte a byte, igual que
  todos los reportes, `theil_*.csv`, las tablas y las figuras. Solo cambió el encabezado
  de `06_evolucion.csv`.

Por eso no hace falta la tabla "antes contra después" de n, suma de pesos y Theil A: no
cambió nada. Los datos crudos se leyeron con *junctions* temporales hacia la carpeta de la
universidad, que se eliminaron al terminar; los 710 `.dta` siguen intactos.

**Optimización.** No se hizo. El Monte Carlo y el bootstrap, que son los bucles costosos,
todavía no existen, y el resto del pipeline corre en unos 13 minutos desde los crudos y en
unos 4 desde `data/processed/`.

**Resultados de P1–P7** (`outputs/inferencia/tablas/resumen_pruebas.csv`; 2026,
submuestra de 2.000 ∝ `fex_aj`):

| | Análisis | Resultado |
|---|---|---|
| P1 | IC 95 % media de ln(ingreso) | 14,22 [14,18; 14,26]. La serie por año sube sobre todo por la inflación (pesos corrientes) |
| P2 | IC 95 % proporción de informales | 0,511 [0,489; 0,532] |
| P3 | t de Welch formal > informal | diferencia en ln = 1,07 (≈ 2,9 veces), t = 32,2, p < 10⁻¹⁰⁰ |
| P4 | F de varianzas de ln(ingreso) | F = 0,41 [0,36; 0,47]: los informales son más desiguales. Brown-Forsythe lo confirma (F = 129,7) |
| P5 | χ² educación × formalidad | χ² = 509 (4 gl), V de Cramér = 0,50 |
| P6 | ln(ingreso) ~ horas | β₁ = 0,025 [0,022; 0,028], R² = 0,13. Residuos no normales y heterocedásticos (se reporta) |
| P7 | Shapiro-Wilk de ln(ingreso), 2024, n = 5.000 | W = 0,954, p ≈ 10⁻³⁷ |

---

## Decisiones para el equipo

Se van agregando a medida que avanza la auditoría. Ninguna se toma sin consultar.

| # | Decisión | Opciones | Origen |
|---|---|---|---|
| D1 | Estrato faltante (~3.500 respondientes por año, de menor ingreso) | (a) dejarlos fuera de todo (hoy); (b) categoría "Sin estrato"; (c) exigir estrato solo en su propia descomposición | ESTADO_PROYECTO, Fase 2 |
| D2 | C y D con pesos o sin pesos | (a) sin pesos (como en la propuesta): en 2024, C sin pesos tiene sesgo +0,024 por compensación de errores; (b) con pesos: aísla el supuesto lognormal (C +0,088, D −0,022) | ESTADO_PROYECTO, Fase 3 §3.4 |
| D3 | Comparación de H3 | (a) 2018 vs 2026; (b) 2022 vs 2026 (mismo marco) como prueba principal y 2018 como referencia | ESTADO_PROYECTO |
| D4 | Ingresos muy bajos | regla de recorte, o solo análisis de sensibilidad | ESTADO_PROYECTO, Fase 2 |
| D5 | Diseño de muestreo de la simulación | O1 uniforme sin reemplazo; O2 uniforme con reemplazo; O3 prob. ∝ peso; O4 pseudopoblación + muestreo desigual | Fase 3 §3.5 |
| D6 | Bootstrap por persona o por vivienda (`DIRECTORIO`) | | ESTADO_PROYECTO |
| D7 | Tratamiento de 2018 por la no respuesta del 13 % | depende de la Fase 2 | Fase 1, hallazgo 1 |
| D8 | Comparar S entre dimensiones con distinto número de grupos (H2) | (a) mantener S; (b) reportar además una medida que no dependa del número de grupos | Fase 1, hallazgo 2 |
| D9 | Ajuste por no respuesta sin estrato (la no respuesta crece con el estrato) | (a) dejarlo como está y reportar la sensibilidad; (b) agregar el estrato a las celdas; (c) calibrar `fex_aj` a los totales de FEX por estrato | Fase 2, §2.4 |
| D10 | Código 7 de `P6430` desde 2022 (trabajadores pagados excluidos) | (a) recodificar por marco (corrección propuesta); (b) dejarlo y documentarlo | Fase 2, §2.9 |
| D11 | Análisis clásicos para cumplir el corte 3 | Aprobar todas, algunas o ninguna de las propuestas P1–P7 | Fase 4, `alineacion_curso.md` §2 |
| D12 | Cómo aplicar pruebas clásicas a una encuesta con pesos | (a) submuestra n = 2.000 con prob. ∝ `fex_aj` (simple, propuesta); (b) paquete `survey` (riguroso, nueva dependencia) | Fase 4 |
| D13 | Interlineado del informe | 1,5 líneas (lectura probable de "1.5 cm" en la guía); confirmar con el profesor | Fase 4 |
