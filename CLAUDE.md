# CLAUDE.md — Fuente de verdad del proyecto

Proyecto de Estadística (73210011), Universidad del Rosario, 2026-II.
Equipo: Gabriel Salcedo (datos), Jerónimo Marín, Isaac Suarez, Santiago Velandia.
La sustentación es individual: todo el código debe poder explicarse línea por línea.
**Limpio y defendible antes que ingenioso.**

## 1. Propósito

1. Comparar por simulación Monte Carlo cuatro estimadores del índice de Theil
   (sesgo, varianza, ECM, eficiencia relativa, consistencia).
2. Con el estimador validado, medir y descomponer (entre/dentro) la desigualdad del
   ingreso laboral en Colombia, 2018–2026, con microdatos de la GEIH (DANE).

Todo el análisis se hace en R.

## 2. Estimadores

Notación: $y_i$ es el ingreso laboral, $w_i$ el factor de expansión, $W = \sum w_i$ y
$\mu = \frac{1}{W}\sum w_i y_i$.

| | Estimador | Fórmula |
|---|---|---|
| A | Theil por sustitución, ponderado | $T = \frac{1}{W}\sum w_i \frac{y_i}{\mu}\ln\frac{y_i}{\mu}$ |
| B | Theil por sustitución, sin ponderar | La fórmula de A con $w_i = 1$ |
| C | Lognormal por método de momentos | $\sigma^2 = \ln(1 + CV^2)$, $T = \sigma^2/2$ |
| D | Lognormal por máxima verosimilitud | $\sigma^2 = \mathrm{Var}(\ln y)$ (divisor $n$), $T = \sigma^2/2$ |

- Descomposición: $T = T_{entre} + T_{dentro}$, con $T_{dentro} = \sum_k s_k T_k$, donde
  $s_k$ es la participación del grupo $k$ en el ingreso total. Se hace para cinco
  dimensiones: educación, formalidad, estrato, región y sexo.
- **Pendiente (lo decide el equipo):** si C y D se calculan con pesos o sin ellos.

## 3. Hipótesis (redacción vigente: `docs/curso/report/primera_entrega_corregida.tex`)

Todas las pruebas son unilaterales, con α = 0,05.

- **H1.** A es consistente y tiene el menor ECM de los cuatro estimadores cuando n
  crece; B, C y D no convergen al valor verdadero. Prueba: t pareada sobre
  $d_j^{(r)} = (\hat T_A^{(r)} - T)^2 - (\hat T_j^{(r)} - T)^2$ con n = 50.000.
  $H_0: \bar d_j \ge 0$ contra $H_1: \bar d_j < 0$, para j ∈ {B, C, D}. Se concluye a
  favor de A si se rechaza $H_0$ para los tres.
- **H2.** En 2026 la educación explica más desigualdad que cada una de las otras
  cuatro dimensiones. Se rechaza $H_0$ si el percentil 5 bootstrap de
  $S_{edu} - S_k$ es mayor que 0 para todo k.
- **H3.** La desigualdad del ingreso laboral fue menor en 2026 que en 2018. Se rechaza
  $H_0$ si el percentil 95 bootstrap de $T_{2026} - T_{2018}$ es menor que 0. Se
  reporta también el tamaño de la diferencia.

No se reescribe ninguna hipótesis después de ver los resultados. Un resultado que la
contradiga se reporta tal cual.

## 4. Decisiones tomadas (no cambiar sin consultar al equipo)

- Meses 1 a 6 de cada año.
- Ingreso = `INGLABO` en pesos corrientes, sin deflactar (el Theil es invariante a la
  escala).
- Población: ocupados de 15 años o más, remunerados, con ingreso laboral positivo,
  en los 24 departamentos comunes al marco 2018 (sin Orinoquía-Amazonía ni San Andrés).
- 2020 se excluye de la serie de desigualdad.
- No respuesta de ingreso: ajuste del peso por celdas (`fex_aj`, `fex_aj_nac`), no se
  borran filas. Las celdas cruzan posición, formalidad, educación, región y sexo.
- Formalidad: `P6920` ∈ {1, 3} (cotiza a pensión o ya es pensionado).
- Educación armonizada a 5 niveles.
- Factor de expansión: `FEX_C_2011` para 2018–2021 y `FEX_C18` para 2022–2026.
- Valor "verdadero" de la simulación: A sobre la base 2024 completa.
- Simulación: 500 réplicas para cada n ∈ {500, 2.000, 10.000, 50.000}.

### Decisiones abiertas (ver `docs/AUDITORIA.md`, §"Decisiones para el equipo")

Diseño de muestreo de la simulación, C y D con o sin pesos, estrato faltante,
2018 vs. 2022 en H3, regla para ingresos muy bajos y bootstrap por vivienda.

## 5. Estructura de carpetas (actual; la estructura objetivo se define en la Fase 6)

```
data/raw/          Microdatos DANE por mes (YYYYMM/*.dta). Ignorado por Git.
data/final/        Etapa 1: base cruda unida por año (.rds ignorado) + reportes/
data/analitica/    Etapa 2: base analítica por año (.rds ignorado) + reportes/
data/resultados/   Etapa 3: Theil (CSV)
outputs/descriptiva/  Etapa 4: tablas y figuras
scripts/           00_ a 04_, en orden de ejecución
docs/              Diccionario DANE, estado del proyecto y auditoría
docs/curso/        Guía del curso y entregas (LaTeX)
```

## 6. Orden de ejecución

1. `scripts/00_verificar_datos.R`: comprueba que los datos estén completos.
2. `scripts/01_base_cruda_anual.R`: `data/raw` → `data/final` (requiere los .dta).
3. `scripts/02_base_analitica_anual.R`: `data/final` → `data/analitica`.
4. `scripts/03_theil.R`: Theil A/B y descomposición → `data/resultados`.
5. `scripts/04_estadistica_descriptiva.R`: → `outputs/descriptiva`.

(Se actualizará cuando exista `run_all.R`.)

## 7. Reglas de Git

- Se trabaja en la rama `revision-general`. **Nunca** se hace commit en `main`.
- Solo Git local: nada de push, nada de crear o cambiar remotos, nada de cambiar
  `git config`. Gabriel revisa y publica desde GitHub Desktop.
  - Git no está en el PATH; se usa
    `%LOCALAPPDATA%\GitHubDesktop\app-*\resources\app\git\cmd\git.exe`.
- **Claude no hace commit** de cambios en la limpieza de datos, las funciones de Theil,
  el Monte Carlo, el bootstrap, las pruebas de hipótesis o la estadística descriptiva.
  Hace el cambio, dice qué archivos cambiaron y qué revisar, y Gabriel hace el commit.
- Claude sí hace commit de estructura, documentación, README, esqueletos LaTeX, tests
  y configuración. Un tema por commit, con el formato `tipo: descripción`, donde
  tipo ∈ {limpieza, theil, montecarlo, descriptiva, inferencia, estructura, datos,
  docs, latex, tests}.
- Antes de cada commit se verifica que no entren `.dta`, credenciales ni archivos de
  más de 50 MB.
- Sin Git LFS, sin reescribir la historia y sin force-push.

## 8. Reglas de estilo

- Código, comentarios, documentos, reportes y mensajes de commit en español.
- R sencillo: `dplyr` y R base, sin trucos. Comentarios que expliquen el *porqué*.
- Rutas relativas con `here()`, nunca `setwd()` ni rutas absolutas.
- Las constantes (años, meses, semilla, grilla de n, réplicas, mínimo por celda)
  van en un archivo de configuración, no repetidas en cada script.
- Semillas fijas en todo lo aleatorio.
- Las tablas y figuras del informe las genera R en `outputs/`; LaTeX las incluye con
  `\input{}` e `\includegraphics{}`. Nunca se copian a mano.
- Los .dta originales nunca se modifican ni se borran. Un archivo dudoso se mueve a
  `_revisar/` en vez de borrarse.

## 9. Números de referencia

Se llena en la Fase 2. Compara los números de la entrega vigente con una corrida nueva.

| Número | Entrega | Corrida actual | ¿Coincide? | Nota |
|---|---|---|---|---|
| Ocupados enero 2018 | 27.693 | | | |
| Ocupados / población / entran al Theil, por año (Tabla 2) | ver entrega | | | |
| % del FEX total por año | ver entrega | | | |
| Theil A por año | — | | | |
| Participación "entre" por dimensión | — | | | |
