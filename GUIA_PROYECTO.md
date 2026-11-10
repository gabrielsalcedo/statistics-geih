# Guía completa del proyecto: ¿Cómo estimar el índice de Theil con la GEIH?

*Universidad del Rosario, Estadística, 2026-II.*
*Equipo: Gabriel Salcedo, Jerónimo Marín, Isaac Suarez y Santiago Velandia.*

Esta guía explica, paso a paso y sin dar nada por sabido, todo lo que se desarrolló en el
proyecto:
- la pregunta;
- los conceptos estadísticos;
- los datos y su limpieza;
- el código;
- el experimento de simulación;
- las pruebas de hipótesis;
- los resultados;
- el informe, la presentación y el póster.

La idea es que cualquier integrante pueda leerla de principio a fin y quedar en capacidad de
explicar y defender cualquier parte del trabajo.

---

## Índice

1. [El problema y la pregunta](#1-el-problema-y-la-pregunta)
2. [Conceptos estadísticos que se usan](#2-conceptos-estadísticos-que-se-usan)
3. [El índice de Theil](#3-el-índice-de-theil)
4. [Los cuatro estimadores](#4-los-cuatro-estimadores)
5. [Hipótesis](#5-hipótesis)
6. [Los datos: la GEIH](#6-los-datos-la-geih)
7. [Depuración y construcción de las bases](#7-depuración-y-construcción-de-las-bases)
8. [El código, script por script](#8-el-código-script-por-script)
9. [Estadística descriptiva](#9-estadística-descriptiva)
10. [El experimento de simulación (H1)](#10-el-experimento-de-simulación-h1)
11. [La prueba de H1](#11-la-prueba-de-h1)
12. [Theil por año y descomposición](#12-theil-por-año-y-descomposición)
13. [Bootstrap: intervalos de confianza, H2 y H3](#13-bootstrap-intervalos-de-confianza-h2-y-h3)
14. [Conclusiones y limitaciones](#14-conclusiones-y-limitaciones)
15. [Los documentos: informe, presentación y póster](#15-los-documentos-informe-presentación-y-póster)
16. [Reproducibilidad, repositorio y Git](#16-reproducibilidad-repositorio-y-git)
17. [Glosario](#17-glosario)
18. [Preguntas probables y cómo responderlas](#18-preguntas-probables-y-cómo-responderlas)

---

## 1. El problema y la pregunta

### ¿Por qué importa?
- Colombia es uno de los países más desiguales de América Latina. El Gini del ingreso de
  los hogares fue 0,551 en 2024 (DANE, 2025).
- Esas cifras **no son la desigualdad "real"**: se calculan con encuestas, así que son
  **estimaciones**.
- Detrás de cada cifra publicada hay una decisión estadística: qué fórmula (estimador) se
  usa y bajo qué supuestos.
- Si se elige mal el estimador, el resultado puede tener **sesgo**: puede equivocarse
  sistemáticamente, aunque se tengan muchísimos datos.

### ¿Qué hace el proyecto?
Tiene dos partes que se conectan:

1. **Parte metodológica.** Compara cuatro formas de estimar el índice de Theil (A, B, C y D)
   con un experimento de simulación, para saber cuál es la mejor con la GEIH.
2. **Parte aplicada.** Con el estimador ganador:
   - mide la desigualdad del ingreso laboral en Colombia entre 2018 y 2026;
   - la descompone por educación, formalidad, sexo, región y estrato;
   - calcula intervalos de confianza y prueba hipótesis.

### Pregunta problema
> De cuatro estimadores candidatos del índice de Theil —ponderado (A), sin ponderar (B),
> lognormal por momentos (C) y lognormal por máxima verosimilitud (D)—, ¿cuál tiene mejores
> propiedades estadísticas (menor sesgo, menor ECM y consistencia) para estimar la
> desigualdad del ingreso laboral a partir de la GEIH?

### Objetivos específicos
1. Definir los cuatro estimadores, sus supuestos y sus propiedades esperadas.
2. Construir un valor de referencia ("valor verdadero") con la GEIH 2024 completa.
3. Simular submuestras de distintos tamaños y medir sesgo, varianza, ECM y eficiencia
   relativa.
4. Decidir cuál estimador es consistente y usarlo en la aplicación.
5. Calcular el Theil de cada año (2018–2026, sin 2020) y su descomposición.
6. Estimar intervalos de confianza por bootstrap y probar H1, H2 y H3.

---

## 2. Conceptos estadísticos que se usan

### Población, muestra, parámetro y estimador
- **Población:** todos los ocupados del país, unos 21,6 millones.
- **Muestra:** las personas que la GEIH encuesta, unas 150.000 por semestre en nuestra base.
- **Parámetro:** un número fijo de la población que no conocemos. Aquí es el índice de
  Theil verdadero, T.
- **Estimador:** una fórmula que se aplica a la muestra para aproximar el parámetro. Se
  escribe con sombrero: T̂.
- **Un estimador es una variable aleatoria.** Con otra muestra daría otro valor. La forma en
  que varían esos valores es su **distribución muestral**.

### Factor de expansión (peso)
- En la GEIH no todas las personas tienen la misma probabilidad de ser encuestadas.
- El **factor de expansión** wᵢ dice a cuántas personas de la población representa cada
  encuestado.
- Ejemplo: Bogotá es el 4,4 % de los encuestados, pero el 19,6 % de los ocupados. Sus
  encuestados tienen pesos grandes.
- **Ponderar** significa usar esos pesos en los cálculos. Así lo que se describe es la
  población, no la muestra.

### Propiedades de un estimador
| Propiedad | Qué significa | Fórmula |
|---|---|---|
| **Sesgo** | Cuánto se equivoca en promedio | Sesgo = E(T̂) − T |
| **Varianza** | Cuánto cambia de una muestra a otra | Var(T̂) = E[(T̂ − E(T̂))²] |
| **Error cuadrático medio (ECM)** | Error total: combina sesgo y varianza | ECM = E[(T̂ − T)²] = Sesgo² + Varianza |
| **Consistencia** | Se acerca al valor verdadero cuando n crece | ECM → 0 cuando n → ∞ |
| **Eficiencia relativa** | Compara el error de dos estimadores | ER = ECM(A) / ECM(j) |
| **Suficiencia** | El estimador usa toda la información relevante de la muestra | Depende de estadísticos suficientes |

**Cómo leer la eficiencia relativa:**
- **ER < 1:** A tiene menos error que el competidor j. Por ejemplo, ER = 0,04 significa que
  el error de A es 4 % del de j, unas 25 veces menor.
- **ER > 1:** el competidor es mejor.

**Por qué el ECM es la medida central:** un estimador puede tener poca varianza y mucho
sesgo, o al revés. El ECM castiga las dos cosas a la vez.

### Simulación Monte Carlo
- Es un experimento hecho en el computador.
- Se toma una "población" conocida, se sacan muchas muestras, se aplica cada estimador a
  cada muestra y se mira cómo se comportan los resultados.
- Así se miden sesgo, varianza y ECM directamente, sin depender de fórmulas teóricas.

### Bootstrap
- Es un método para aproximar la distribución muestral de un estimador cuando no hay una
  fórmula sencilla para su varianza. Es el caso del Theil (Efron y Tibshirani, 1993).
- Funciona así:
  1. Se remuestrea la muestra **con reemplazo**, del mismo tamaño.
  2. Se recalcula el estimador en esa nueva muestra.
  3. Se repite muchas veces (aquí, 500).
- Los valores obtenidos imitan la variación de muestra a muestra.

### Pruebas de hipótesis
- Se plantea una hipótesis nula H₀ (lo que se asume hasta tener evidencia en contra) y una
  alternativa H₁ (lo que queremos mostrar).
- Se rechaza H₀ si la evidencia es lo bastante fuerte. Usamos α = 0,05.
- Todas las pruebas del proyecto son **unilaterales**: las hipótesis tienen dirección ("A es
  mejor", "la educación explica más", "la desigualdad bajó").

---

## 3. El índice de Theil

### Definición
Para N personas con ingresos Y₁, …, Y_N y media μ:

    T = (1/N) Σⱼ (Yⱼ/μ) · ln(Yⱼ/μ)

### Intuición
- Si todos ganan lo mismo, cada Yⱼ/μ = 1 y ln(1) = 0, así que **T = 0**.
- Cuanto más concentrado está el ingreso, mayor es T. No tiene un máximo fijo de 1, a
  diferencia del Gini: su máximo es ln N.
- Viene de la teoría de la información (Theil, 1967). Mide qué tan "lejos" está la
  distribución observada de la igualdad perfecta.
- Una persona con ingreso 0 aporta 0 (el límite de x·ln x es 0). Solo el estimador D
  necesita ingresos estrictamente positivos, porque usa ln y.

### Ejemplo a mano
Cuatro personas con ingresos 1, 3, 4 y 4. La media es μ = 3.

| Persona | y | y/μ | (y/μ)·ln(y/μ) |
|---|---|---|---|
| 1 | 1 | 0,333 | −0,3662 |
| 2 | 3 | 1,000 | 0 |
| 3 | 4 | 1,333 | 0,3836 |
| 4 | 4 | 1,333 | 0,3836 |
| **Suma** | | | **0,4010** |

T = 0,4010 / 4 = **0,1003**

### La propiedad clave: descomposición entre/dentro
Si la población se divide en grupos k (por ejemplo, niveles educativos), el Theil se separa
**exactamente** en dos partes (Shorrocks, 1980):

    T = Σₖ sₖ · ln(μₖ/μ)   +   Σₖ sₖ · Tₖ
          (entre grupos)        (dentro de los grupos)

- **sₖ** es la participación del grupo k en el **ingreso** total, no en la población.
- **μₖ** es la media del grupo y **Tₖ** el Theil dentro del grupo.
- **"Entre"** es la desigualdad que habría si cada persona ganara la media de su grupo:
  mide las brechas entre grupos.
- **"Dentro"** es la desigualdad entre personas del mismo grupo.
- **% explicado por una dimensión** = entre / T × 100.

**Ejemplo, continuando el anterior.** Grupo 1 = {1, 3} y grupo 2 = {4, 4}.

| | Grupo 1 | Grupo 2 |
|---|---|---|
| Media μₖ | 2 | 4 |
| Participación en el ingreso sₖ | 4/12 = 1/3 | 8/12 = 2/3 |
| Theil dentro Tₖ | 0,1308 | 0 |

- Entre = (1/3)·ln(2/3) + (2/3)·ln(4/3) = −0,1352 + 0,1918 = **0,0566**
- Dentro = (1/3)·0,1308 + (2/3)·0 = **0,0436**
- Entre + dentro = 0,1002 ≈ T. **La descomposición cuadra.** El código verifica esto
  siempre.
- En este ejemplo la división en grupos explica 0,0566 / 0,1003 = 56 % de la desigualdad.

---

## 4. Los cuatro estimadores

Sea yᵢ el ingreso del encuestado i, wᵢ su factor de expansión, n el tamaño de muestra,
W = Σ wᵢ y μ̂_w = (1/W) Σ wᵢ yᵢ la media ponderada.

### A: ponderado, por sustitución (*plug-in*)

    T̂_A = (1/W) Σᵢ wᵢ (yᵢ/μ̂_w) ln(yᵢ/μ̂_w)

- **Idea:** tomar la fórmula poblacional y reemplazar la población por la muestra,
  ponderada con los factores de expansión. Cada encuestado "cuenta" por las personas que
  representa.
- **Supuestos:** ninguno sobre la forma de la distribución. Solo se necesitan los pesos.
- **Propiedad esperada:** consistente. Con muestras pequeñas tiene un sesgo pequeño hacia
  abajo.

### B: sin ponderar

Es la misma fórmula que A con wᵢ = 1 para todos.
- **Problema:** mide la desigualdad **de los encuestados**, no la de la población.
- Como la GEIH sobrerrepresenta unas regiones y subrepresenta otras, B es **sesgado aunque n
  sea enorme**: no es consistente para el Theil poblacional.

### C: lognormal por el método de los momentos

Si ln y ~ Normal(m, σ²), entonces se cumple que **T = σ²/2** (Cowell, 2011). Basta estimar
σ².

C iguala el coeficiente de variación de la muestra (CV = s/ȳ) con el de una lognormal, que
es CV² = e^{σ²} − 1. Despejando:

    σ̂² = ln(1 + CV²)      →      T̂_C = σ̂²/2

- La varianza s² divide por n.
- No usa pesos, como en la primera entrega.

### D: lognormal por máxima verosimilitud

El estimador de máxima verosimilitud de σ² es la varianza de ln y **dividida por n**:

    σ̂² = (1/n) Σᵢ (ln yᵢ − media(ln y))²      →      T̂_D = σ̂²/2

- **Por qué divide por n y no por n − 1:** el estimador de máxima verosimilitud de la
  varianza normal divide por n. La función `var()` de R divide por n − 1; ese es el
  estimador insesgado, que es otra cosa.
- **Suficiencia:** depende de los datos solo a través de Σ ln yᵢ y Σ (ln yᵢ)², que son
  estadísticos suficientes de la normal.
- Tiene **varianza muy baja**, pero si el ingreso no es lognormal, está sesgado y el sesgo no
  desaparece.

### Resumen

| Estimador | Usa pesos | Supone lognormal | Consistente con la GEIH |
|---|---|---|---|
| A | Sí | No | **Sí** |
| B | No | No | No (sesgo por diseño muestral) |
| C | No | Sí | No (sesgo por supuesto falso y por pesos) |
| D | No | Sí | No (sesgo por supuesto falso y por pesos) |

---

## 5. Hipótesis

| Hipótesis | Enunciado | Cómo se prueba |
|---|---|---|
| **H1** | A es consistente y tiene el menor ECM cuando n crece; B, C y D no convergen al valor verdadero | Simulación y prueba t pareada unilateral con n = 50.000 |
| **H2** | En 2026, la educación explica más desigualdad (componente entre) que cada una de las otras cuatro dimensiones | Bootstrap: percentil 5 de S*_edu − S*_k > 0 para todas las k |
| **H3** | La desigualdad del ingreso laboral fue menor en 2026 que en 2018 | Bootstrap: percentil 95 de T*_2026 − T*_2018 < 0 |

Todas son unilaterales, con α = 0,05.

---

## 6. Los datos: la GEIH

### ¿Qué es?
- La **Gran Encuesta Integrada de Hogares** del DANE.
- Es mensual, probabilística y nacional, con unos 315.000 hogares al año (DANE, 2023).
- Es la única fuente que tiene ingreso laboral y factores de expansión.

### ¿Qué se usó?
- **Meses:** enero a junio de cada año, de 2018 a 2026, para comparar el mismo semestre.
- **Módulos:** se unen tres, con las llaves `DIRECTORIO`, `SECUENCIA_P`, `HOGAR` y `ORDEN`:
  1. **Ocupados:** ingreso, posición ocupacional, pensión, horas y tamaño de empresa.
  2. **Características generales:** sexo, edad y educación.
  3. **Datos del hogar y la vivienda:** estrato. Se une sin `ORDEN`, porque el estrato es del
     hogar.
- **Dos marcos muestrales:**
  - Marco 2005, en 2018–2021: factor `FEX_C_2011`. Los archivos vienen en Cabecera, Resto y
    Área; se apilan Cabecera + Resto, porque Área está contenida en Cabecera.
  - Marco 2018, desde 2022: factor `FEX_C18`. Algunas variables cambian de nombre; por
    ejemplo, la educación pasa de `P6210` a `P3042`.
- **2020 no se usa para el Theil:** por la pandemia la encuesta fue telefónica, falta el
  ingreso de la mayoría y no se preguntó el estrato.

### Variables (21 columnas de las bases crudas)
| Grupo | Columnas |
|---|---|
| Llaves y fecha | DIRECTORIO, SECUENCIA_P, HOGAR, ORDEN, ANIO, MES |
| Diseño y ubicación | FEX, DPTO, CLASE |
| Ingreso | INGLABO (ingreso laboral mensual, pesos corrientes) |
| Trabajo | P6430 (posición), P6920 (cotiza a pensión), P6800 (horas), TAM_EMPRESA |
| Persona | P6040 (edad), SEXO, EDUC |
| Hogar | ESTRATO |
| Trazabilidad | columnas `*_FUENTE`: qué variable original se usó en cada marco |

### Escalas de medición
| Variable | Tipo | Escala |
|---|---|---|
| Ingreso laboral | Cuantitativa continua | Razón |
| Edad, horas | Cuantitativas | Razón |
| Educación (5 niveles) | Cualitativa | Ordinal |
| Estrato (1–6) | Cualitativa | Ordinal |
| Formalidad (sí/no) | Cualitativa | Nominal (dicotómica) |
| Sexo | Cualitativa | Nominal (dicotómica) |
| Región (5) | Cualitativa | Nominal |

---

## 7. Depuración y construcción de las bases

### Principio: *marcar, no borrar*
- La base final de cada año conserva **a todos los ocupados**.
- Cada criterio de depuración se guarda como un **indicador** (verdadero/falso).
- Así se puede contar cuántas personas excluye cada paso. Esa es la tabla de
  trazabilidad.

### Criterios (indicadores)
| Indicador | Qué exige | Por qué |
|---|---|---|
| `f_edad` | 15 años o más | Población en edad de trabajar |
| `f_remunerado` | Posición distinta de "sin remuneración" | Su ingreso es cero por definición |
| `f_cobertura` | Uno de los 24 departamentos comunes | El marco 2018 agrega 9 departamentos que antes no existían; sin esto, la serie no es comparable |
| `f_no_cero` | Ingreso distinto de 0 | Que los cuatro estimadores comparen la misma población (D necesita y > 0) |
| `f_dims` | Las cinco dimensiones completas | Para poder descomponer |
| `responde` | Reporta ingreso > 0 | Distingue a quien responde de quien no |
| `en_poblacion` | Todos los anteriores | Población de estudio |

### Armonización entre marcos
- **Educación:** 5 niveles comunes (ninguno o preescolar, primaria, secundaria, media y
  superior).
- **Formalidad:** formal si cotiza a pensión o ya es pensionado (`P6920` = 1 o 3).
- **Región:** según el departamento, en Bogotá, Caribe, Oriental, Central y Pacífica.
- **Estrato:** 1 a 6. Los códigos 0 y 9 pasan a NA.
- **Tamaño de empresa:** 5 rangos.
- Los códigos "no sabe" (9, 99) quedan en NA.

### Ajuste por no respuesta (`fex_aj`)
**Problema:** algunas personas no reportan su ingreso. Si solo se borran, se pierde
población, y si quienes no responden son distintos (por ejemplo, más ricos), se sesga el
resultado.

**Solución:** repartir su peso entre quienes sí responden y se les parecen.
1. Se forman **celdas** de personas parecidas: posición × formalidad × educación × región ×
   sexo.
2. En cada celda:

       fex_aj = FEX × (suma de FEX de toda la celda) / (suma de FEX de los que responden)

3. Si una celda tiene **menos de 30 respondientes**, se fusiona con otras: primero se quita el
   sexo, luego la región, etc.
4. El script verifica que **el total del FEX se conserva**, es decir, que la población
   representada no cambia.

### Tamaño de las bases (trazabilidad)
| Año | Ocupados | Población de estudio | Entran al Theil |
|---|---|---|---|
| 2018 | 174.668 | 162.300 | 141.025 |
| 2019 | 168.441 | 156.616 | 151.283 |
| 2020 | 146.862 | 96.931 | 57.042 (no se usa) |
| 2021 | 146.094 | 136.479 | 129.750 |
| 2022 | 194.647 | 168.270 | 160.946 |
| 2023 | 183.136 | 160.299 | 157.776 |
| 2024 | 178.204 | 156.063 | 152.213 |
| 2025 | 176.176 | 154.659 | 153.340 |
| 2026 | 177.195 | 155.262 | 154.657 |

Los ocupados de cada año coinciden **exactamente** con la Tabla 2 de la primera entrega.

---

## 8. El código, script por script

Todo está en R 4.5.2. Se abre `statistics-geih.Rproj` y se corre desde la raíz.

| Script | Qué hace | Entrada → salida | Tiempo |
|---|---|---|---|
| `00_funciones.R` | Fórmulas del Theil y de los 4 estimadores, lectura y escritura de bases, verificaciones | — | — |
| `01_extraer_crudas.R` | Opcional. Lee los `.dta` del DANE y arma las crudas | `.dta` → `data/raw/` | ~5 min |
| `02_bases_finales.R` | Armoniza, marca indicadores, ajusta pesos, trazabilidad | `data/raw/` → `data/final/` | ~2 min |
| `03_descriptiva.R` | Estadística descriptiva ponderada y 4 figuras | `data/final/` → `outputs/`, `latex/` | <1 min |
| `04_theil_anual.R` | Theil por año (A, A sin ajuste, B) y descomposición | → `outputs/`, 2 figuras | <1 min |
| `05_simulacion.R` | Experimento Monte Carlo y prueba de H1 | base 2024 → `outputs/`, 2 figuras | ~0,5 min |
| `06_bootstrap.R` | IC del 95 %, H2 y H3 | → `outputs/`, 1 figura | ~6 min |
| `correr_todo.R` | Revisa paquetes y corre 02 a 06 | — | ~10 min |

### Detalles importantes de `00_funciones.R`
- **`theil_decomp(y, w, g)`:** calcula el Theil ponderado. Si se le da un grupo `g`, devuelve
  entre, dentro y la participación de cada grupo. Se detiene si entre + dentro ≠ total.
- **`n_ef`:** tamaño efectivo de Kish, W² / Σw². Dice a cuántas observaciones "sin pesos"
  equivale la muestra ponderada.
- **Escritura exacta:** los decimales se guardan con 17 cifras (`%.17g`), para que al leer la
  base el Theil salga idéntico hasta el último decimal.
- **Cuatro verificaciones automáticas (`stopifnot`):**
  1. Ingresos iguales dan T = 0.
  2. A con pesos iguales a 1 es igual a B.
  3. El ejemplo de clase hecho a mano da los valores esperados.
  4. Entre + dentro = total.

### Paquetes de R
`dplyr` y `tidyr` (manejo de datos), `ggplot2` y `scales` (figuras), `quantreg` (cuantiles
ponderados para los diagramas de caja) y `haven` (solo en 01, para leer `.dta`).

---

## 9. Estadística descriptiva

Todo está **ponderado con `fex_aj`**: describe a los 21,6 millones de ocupados, no a los
154.657 encuestados de 2026.

### Qué se calcula
- **Medidas de tendencia central y dispersión** del ingreso, ln(ingreso), edad y horas:
  media, mediana, moda, cuantiles, desviación, CV, asimetría y curtosis.
- **Tablas de frecuencias.** El ingreso se agrupa en salarios mínimos (SMMLV); con clases
  iguales casi todos caerían en la primera.
- **Tablas cruzadas:** educación × formalidad, sexo × formalidad, región × formalidad y
  estrato × educación.
- **Participación en la población frente a participación en el ingreso** de cada grupo. Es
  la intuición del componente "entre".

### Hallazgos (2026)
- **Ponderar importa:** Bogotá es el 4,4 % de los encuestados y el 19,6 % de los ocupados.
- **Composición:** 57 % son hombres, 38 % tiene educación superior, 50,6 % es informal y dos
  de cada tres viven en estrato 1 o 2.
- **Las dimensiones están relacionadas:**
  - la informalidad es 95,2 % sin educación y 21,9 % con educación superior;
  - en el estrato 6 el 88 % tiene educación superior, frente al 16,6 % en el estrato 1.
- **El ingreso es muy asimétrico:** la media es $2.314.067 y la mediana $1.750.000, con CV de
  133 % y asimetría de 9,9.
- **Pico en el salario mínimo:** el 15,5 % gana alrededor de un SMMLV, el 39,5 % gana menos y
  solo el 4,3 % gana más de cuatro.
- **Brechas:**
  - el ingreso medio del estrato 6 es 4,2 veces el promedio, y el del estrato 1 es 0,56
    veces;
  - quienes tienen educación superior son el 38 % de los ocupados y reciben el 60,5 % del
    ingreso.
- **ln(ingreso) no es normal:** tiene asimetría −0,77, curtosis en exceso 4,11 (colas
  pesadas) y un pico en el salario mínimo. **Esto anticipa que C y D van a fallar.**

### Cómo leer cada figura
| Figura | Qué muestra | Qué hay que señalar |
|---|---|---|
| Barras de variables cualitativas | % de ocupados en cada categoría | La composición de la población |
| Histograma del ingreso (hasta 6 SMMLV, 98,2 % de los ocupados) | Densidad ponderada | El pico en 1 SMMLV (línea roja) y la cola larga a la derecha |
| Diagramas de caja por grupo (escala log.) | Mediana, cuartiles y bigotes ponderados | Las cajas del estrato 6 y de educación superior están muy arriba |
| ln(ingreso) frente a la normal | Histograma y curva normal con la misma media y desviación | El histograma no sigue la curva: hay pico y colas |

---

## 10. El experimento de simulación (H1)

### Diseño
1. **"Población":** la base 2024 completa (152.213 personas, con sus pesos).
2. **Valor de referencia:** T = estimador A sobre toda esa base = **0,5043**.
3. **Tamaños de muestra:** n = 500, 2.000, 10.000 y 50.000.
4. **Réplicas:** para cada n, **500 submuestras** por muestreo aleatorio simple **sin
   reemplazo**. Cada persona conserva su `fex_aj`.
5. En cada submuestra se calculan A, B, C y D.
6. **Medidas:**
   - sesgo = media de los 500 valores − T;
   - varianza (dividiendo por 500, para que ECM = sesgo² + varianza exactamente);
   - ECM = media de (T̂ − T)²;
   - ER = ECM(A) / ECM(j).
7. **Semilla fija** (`set.seed(2024)`): cualquiera que corra el código obtiene exactamente los
   mismos números.

### Resultados (Tabla 1 del informe)
| | n = 500 | 2.000 | 10.000 | 50.000 |
|---|---|---|---|---|
| **Sesgo A** | −0,0321 | −0,0095 | −0,0020 | 0,0003 |
| Sesgo B | −0,0847 | −0,0795 | −0,0775 | −0,0766 |
| Sesgo C | −0,0275 | 0,0032 | 0,0195 | 0,0243 |
| Sesgo D | −0,0773 | −0,0777 | −0,0778 | −0,0780 |
| **ECM A (×1.000)** | 23,89 | 7,49 | 1,83 | 0,25 |
| ECM B (×1.000) | 13,43 | 8,16 | 6,40 | 5,93 |
| ECM C (×1.000) | 21,95 | 9,87 | 2,98 | 0,97 |
| ECM D (×1.000) | 7,62 | 6,43 | 6,13 | 6,09 |
| ER frente a B | 1,78 | 0,92 | 0,29 | 0,04 |
| ER frente a C | 1,09 | 0,76 | 0,61 | 0,26 |
| ER frente a D | 3,14 | 1,17 | 0,30 | 0,04 |

### Interpretación
1. **Solo A es consistente.** Su sesgo va a cero y su ECM baja sin parar al crecer n.
2. **B y D convergen a un valor equivocado,** cerca de 0,427, un 15 % por debajo de T:
   - B, por ignorar el factor de expansión;
   - D, por el supuesto lognormal falso.
3. **C conserva un sesgo hacia arriba** (+0,024, cerca de 5 %).
4. **Con n = 500, A no es el mejor.** D tiene un ECM tres veces menor porque su varianza es
   bajísima, aunque esté sesgado. Esto muestra el **trade-off sesgo–varianza**: con muestras
   pequeñas la varianza pesa más; con muestras grandes, el sesgo domina. Desde n = 10.000, A
   gana.
5. **¿Por qué A subestima con muestras pequeñas?** Los ingresos muy altos son pocos, y una
   submuestra pequeña rara vez los incluye. Sin ellos, la desigualdad parece menor.
6. **Con n = 50.000,** el ECM de A es entre 4 y 24 veces menor que el de los demás.

### Figuras
- **ECM según n:** ambos ejes en escala logarítmica. La línea de A baja de forma recta; B y D
  se aplanan.
- **Distribución de las réplicas con n = 50.000:** un histograma por estimador y una línea en
  T. A está centrado en T; B y D, lejos.

---

## 11. La prueba de H1

- **Qué se compara:** en cada réplica r con n = 50.000 se calcula la diferencia de pérdidas

      d_j,r = (T̂_A,r − T)² − (T̂_j,r − T)²

  Si A es mejor, d es negativa.
- **Hipótesis:** H₀: media(d_j) ≥ 0 frente a H₁: media(d_j) < 0.
- **Prueba:** t pareada unilateral, `t.test(perdida_A, perdida_j, paired = TRUE,
  alternative = "less")`.
- **¿Por qué pareada?** A y j se calculan **sobre la misma submuestra**. Comparar dentro de
  cada réplica elimina la variación que viene de la muestra.

| Competidor | Media de d | t | gl | Valor p | Decisión |
|---|---|---|---|---|---|
| B | −0,00567 | −109,41 | 499 | < 0,001 | Se rechaza H₀ |
| C | −0,00071 | −14,89 | 499 | < 0,001 | Se rechaza H₀ |
| D | −0,00584 | −219,18 | 499 | < 0,001 | Se rechaza H₀ |

**Conclusión: los datos respaldan H1.**

**Matiz:** el número de réplicas lo fija el investigador. Con más réplicas, cualquier
diferencia pequeña sale "significativa". Por eso lo que importa es el **tamaño** de la
diferencia, que muestra la eficiencia relativa (0,04 y 0,26).

---

## 12. Theil por año y descomposición

### Theil por año
Se calcula con tres pesos:
- **A con `fex_aj`:** el estimador principal.
- **A con el `FEX` original:** sin ajuste por no respuesta, como chequeo.
- **B sin pesos:** para ver el sesgo en datos reales.

| Año | A (principal) | IC 95 % bootstrap | A sin ajuste | B |
|---|---|---|---|---|
| 2018 | 0,4392 | [0,4220; 0,4553] | 0,4322 | 0,3891 |
| 2019 | 0,4772 | [0,4597; 0,4955] | 0,4733 | 0,4126 |
| 2021 | 0,4739 | [0,4540; 0,4968] | 0,4622 | 0,4150 |
| 2022 | **0,5381** (máximo) | [0,5097; 0,5725] | 0,5314 | 0,4536 |
| 2023 | 0,5135 | [0,4932; 0,5345] | 0,5083 | 0,4382 |
| 2024 | 0,5043 | [0,4842; 0,5257] | 0,4981 | 0,4273 |
| 2025 | 0,4609 | [0,4426; 0,4804] | 0,4576 | 0,3916 |
| 2026 | **0,4288** (mínimo) | [0,4124; 0,4459] | 0,4279 | 0,3921 |

**Lectura:**
- La desigualdad subió hasta 2022 y después bajó cada año, hasta su nivel más bajo en 2026.
- **El salto de 2022 coincide con el cambio de marco muestral y de factor de expansión.**
  También aparece en B, que no usa pesos, así que parte de él puede ser metodológica.
- **B siempre es entre 0,04 y 0,08 menor que A.** Confirma con datos reales lo que mostró la
  simulación: ignorar los pesos subestima la desigualdad.

### Descomposición (% del Theil explicado "entre" grupos)
| Dimensión | Rango 2018–2026 | 2026 |
|---|---|---|
| Estrato | 31–38 % | 35 % |
| Educación | 24–27 % | 25,3 % |
| Formalidad | 22–27 % | 24,8 % |
| Región | 5–9 % | — |
| Sexo | < 1 % | — |

**Lectura:**
- **El estrato es la dimensión que más explica.** Educación y formalidad van casi empatadas.
- **La mayor parte de la desigualdad ocurre dentro de los grupos.** Incluso con el estrato,
  unos dos tercios se dan entre personas del mismo estrato.
- **Los porcentajes no se suman,** porque las dimensiones están correlacionadas: el estrato
  alto suele venir con educación superior y empleo formal.
- **Cuidado al comparar:** el porcentaje "entre" tiende a crecer con el número de grupos. El
  estrato tiene 6 y el sexo 2.

---

## 13. Bootstrap: intervalos de confianza, H2 y H3

### Procedimiento
1. Para cada año se remuestrean **personas con reemplazo**, el mismo número que hay en la
   base. Cada persona conserva su `fex_aj`.
2. En cada réplica se calcula el Theil (A) y, en 2026, las cinco descomposiciones.
3. Se repite **500 veces** con semilla fija (`set.seed(2026)`).

### Intervalos de confianza del 95 % (método de percentiles)
- El intervalo va del **percentil 2,5 al percentil 97,5** de los 500 valores bootstrap.
- No supone normalidad: usa directamente la distribución simulada.
- Son los intervalos de la tabla de la sección 12 y de la figura con barras de error.

### H2: ¿la educación explica más que cada otra dimensión?
1. En cada réplica b se calcula S*_edu − S*_k, donde S es el % explicado "entre".
2. Se rechaza H₀ solo si el **percentil 5** de esa diferencia es **mayor que 0 para todas** las
   dimensiones k.

| Comparación | Percentil 5 | ¿La educación explica más? |
|---|---|---|
| Frente al sexo | +0,235 | Sí |
| Frente a la región | +0,165 | Sí |
| Frente a la formalidad | −0,003 | No (empate) |
| Frente al estrato | −0,113 | No (el estrato explica unos 10 puntos más) |

**Conclusión: no se rechaza H₀. Los datos no respaldan H2.**

### H3: ¿la desigualdad bajó entre 2018 y 2026?
- **Diferencia observada:** T_2026 − T_2018 = 0,4288 − 0,4392 = **−0,0103**.
- **Regla:** se rechaza H₀ si el percentil 95 de T*_2026 − T*_2018 es menor que 0.
- **Resultado:** el percentil 95 = **+0,0085**, mayor que 0. Una caída de cero es compatible
  con los datos.
- **Conclusión: no se rechaza H₀. La reducción no es significativa.** Los intervalos de 2018
  y 2026 se superponen.
- **Matiz:** dentro del mismo marco muestral, la caída entre 2022 (0,538) y 2026 (0,429) es
  grande y los intervalos no se superponen.

---

## 14. Conclusiones y limitaciones

### Conclusiones
1. **Con la GEIH hay que usar el estimador ponderado (A).** Es el único consistente.
   Ignorar el factor de expansión (B) o suponer lognormalidad (C, D) produce sesgos que no
   desaparecen con más datos: B y D subestiman la desigualdad en cerca de 15 % y C la
   sobreestima en cerca de 5 %.
2. **El supuesto lognormal falla** porque el ingreso laboral tiene un pico en el salario
   mínimo y colas pesadas.
3. **La desigualdad** subió hasta 2022 y bajó hasta su mínimo en 2026, pero la diferencia con
   2018 no es significativa (H3).
4. **El estrato es lo que más explica la desigualdad;** educación y formalidad casi empatan
   (H2 no se cumple). La mayor parte de la desigualdad está dentro de los grupos.

### Limitaciones (hay que saberlas decir)
- **El valor de referencia de la simulación es el propio A sobre la GEIH 2024.** El
  experimento compara los demás con el Theil ponderado, no con la población colombiana real.
- **Cambio de marco en 2022:** parte del salto puede ser metodológico.
- **El bootstrap remuestrea personas** e ignora los conglomerados de la encuesta, así que los
  intervalos pueden quedar algo estrechos.
- **No respuesta y estrato:** la no respuesta es mayor en estratos altos (en 2018 no
  responde el 27 % del estrato 6), y el ajuste no usa el estrato. Puede subestimar la
  desigualdad de los primeros años.
- **Las dimensiones están correlacionadas,** así que sus aportes no son independientes.
- **Los ingresos altos suelen subreportarse en encuestas.**
- **Los resultados indican asociación, no causalidad.**
- **Con muestreo sin reemplazo y n = 50.000** (un tercio de la base), la varianza baja algo
  más de lo normal (corrección por población finita ≈ 0,67).

### Decisiones del equipo
- **Código 7 de `P6430` desde 2022.** El DANE lo llama "sin remuneración", pero el 99 % de
  esas personas tiene ingreso. Se siguió la clasificación del DANE (unas 3.400 personas por
  año quedan fuera) y el informe lo reporta como limitación. Incluirlas bajaría el Theil de
  2022–2026 en cerca de 0,003.
- **Ingresos iguales a cero.** El informe explica que se excluyen para que los cuatro
  estimadores se calculen sobre la misma población, porque C y D usan logaritmos.
- **Roles del equipo.** La rúbrica evalúa "roles y responsabilidades". El informe ya no tiene
  anexos, así que el equipo debe decidir dónde presentarlos (por ejemplo, en la sustentación).

---

## 15. Los documentos: informe, presentación y póster

Los tres están en `latex/` y usan las mismas figuras (`fig_*.pdf`, generadas por R).

| Documento | Archivo | Formato | Contenido |
|---|---|---|---|
| Informe | `informe.tex` | APA 7, Times 12, interlineado 1,5, 12 páginas, sin anexos | Portada; análisis en las páginas 2 a 11 (introducción, pregunta, objetivos, estimadores, datos, hipótesis, cómo hicimos el trabajo, descriptiva, resultados, pruebas, discusión con limitaciones y ética, conclusiones); referencias |
| Presentación | `beamer.tex` | 16:9, estilo minimalista (blanco, gris oscuro y un acento azul), 18 diapositivas | Problema, datos y método, resultados, conclusiones, referencias |
| Póster | `poster.tex` | 70 × 100 cm, una página, dos columnas, mismo estilo minimalista | Izquierda: pregunta, hipótesis, datos, estimadores y simulación. Derecha: ingreso, desigualdad, descomposición, pruebas y conclusiones |

**Tablas y figuras del informe:**
- **Tablas:**
  1. Variables.
  2. Personas después de la depuración.
  3. Etapas del proyecto.
  4. Medidas descriptivas de 2026.
  5. Resultados de la simulación.
  6. Theil por año con sus intervalos de confianza.
- **Figuras:**
  1. Histograma del ingreso.
  2. ECM según n.
  3. Descomposición.
- La prueba t de H1 se reporta en el texto.

### Por qué compilan rápido ahora
- El límite del plan gratuito de Overleaf es de 10 segundos. Lo que más tardaba era **biber**
  (la bibliografía APA): unos 33 segundos solo para el informe.
- **Ahora las referencias APA están escritas dentro de cada `.tex`.** No se necesita biber ni
  `references.bib`, que queda en el repositorio solo como registro de las fuentes.
- La fuente Times se carga con `mathptmx`, más liviano que `newtx`.
- Las figuras son PDF vectoriales de 5 a 7 KB.
- **Tiempos locales completos (desde cero, en Windows):** informe ~6 s, póster ~4 s y
  presentación ~10 s. Los servidores de Overleaf suelen ser más rápidos. Además, después de
  la primera compilación, Overleaf reutiliza los auxiliares y basta una pasada.

### Cómo compilar en Overleaf
1. Crear un proyecto en blanco y borrar `main.tex`.
2. Subir **a la raíz** los archivos (no la carpeta): `informe.tex`, `beamer.tex`,
   `poster.tex`, `ur.png` y los 9 `fig_*.pdf`.
3. *Menu > Compiler* = pdfLaTeX; *Main document* = el archivo que se quiera compilar.
4. Si alguna vez vuelve el timeout:
   - *Menu > Compile mode: Fast [draft]* para editar;
   - o compilar en el computador con `latexmk -pdf archivo.tex`.

### Formato APA en el informe
- Títulos de nivel 1 centrados y en negrita; de nivel 2, a la izquierda y en negrita.
- Tablas y figuras con número en negrita, título en cursiva y una *Nota.* debajo.
- Citas autor–año en el texto, por ejemplo Theil (1967) o (DANE, 2025).
- Referencias con sangría francesa, en orden alfabético.

---

## 16. Reproducibilidad, repositorio y Git

### Estructura
```
statistics-geih/
├── data/raw/      geih_cruda_<año>.csv.gz  (crudas, en Git)
├── data/final/    geih_<año>.csv.gz        (bases depuradas, en Git)
├── outputs/       21 tablas CSV
├── scripts/       00 a 06 y correr_todo.R
├── latex/         informe, presentación, póster, logo y figuras
├── README.md, .gitignore, statistics-geih.Rproj
├── GUIA_PROYECTO.md               esta guía
├── ORGANIZACION_PRESENTACION.md   guion de la presentación en 4 partes
```

### Por qué es reproducible
- **Semillas fijas:** 2024 en la simulación y 2026 en el bootstrap.
- **Escritura exacta de decimales:** 17 cifras.
- **Figuras PDF sin fecha interna** (`timestamp = FALSE`).
- **Resultado:** una corrida desde cero, siguiendo el README (unos 11 minutos), produce bases,
  tablas y figuras **idénticas byte a byte** a las del repositorio.
- **Los `.dta` del DANE (62 GB) nunca entran a Git.** Las crudas en CSV permiten replicar
  todo sin ellos.

### Git
- **Rama de trabajo:** `simplificacion`.
- **Para entregar:** *Push origin* en GitHub Desktop y un pull request hacia `main`.
- **La rama `revision-general` se dejó de usar.** Se borra en GitHub si aún existe.

---

## 17. Glosario

| Término | Significado |
|---|---|
| Bootstrap | Remuestreo con reemplazo para aproximar la distribución de un estimador |
| Componente entre | Desigualdad debida a las diferencias de medias entre grupos |
| Componente dentro | Desigualdad entre personas del mismo grupo |
| Consistencia | El estimador se acerca al valor verdadero cuando n crece |
| CV | Coeficiente de variación: desviación / media |
| ECM | Error cuadrático medio = sesgo² + varianza |
| Eficiencia relativa | ECM(A) / ECM(j); menor que 1 significa que A es mejor |
| Factor de expansión | Cuántas personas de la población representa cada encuestado |
| `fex_aj` | Factor de expansión ajustado por no respuesta de ingreso |
| GEIH | Gran Encuesta Integrada de Hogares (DANE) |
| Lognormal | Distribución cuyo logaritmo es normal |
| Máxima verosimilitud | Método que elige el parámetro que hace más probable la muestra observada |
| Método de los momentos | Método que iguala momentos muestrales y teóricos |
| Marco muestral | El listado del que se selecciona la muestra; cambió en 2022 |
| Monte Carlo | Experimento de simulación con muestras aleatorias repetidas |
| Plug-in (sustitución) | Estimador que aplica la fórmula poblacional a la muestra |
| Prueba t pareada | Compara dos mediciones hechas sobre las mismas unidades |
| Sesgo | Error promedio de un estimador: E(T̂) − T |
| SMMLV | Salario mínimo mensual legal vigente |
| Tamaño efectivo de Kish | W² / Σw²: equivalente sin pesos de una muestra ponderada |

---

## 18. Preguntas probables y cómo responderlas

**¿Por qué el Theil y no el Gini?**
Porque el Theil se descompone **exactamente** en entre y dentro de grupos, y eso es
necesario para saber qué dimensión explica la desigualdad. El Gini no se descompone así.

**¿Por qué ponderar?**
Porque la GEIH no le da a todos la misma probabilidad de ser encuestados. Sin pesos, B
describe a los encuestados y subestima la desigualdad en cerca de 15 %.

**¿Por qué el estimador D divide por n?**
Porque el estimador de máxima verosimilitud de σ² divide por n. Dividir por n − 1 da el
estimador insesgado, que es otro estimador.

**Si A es el mejor, ¿por qué con n = 500 tiene más ECM que D?**
Porque el ECM suma sesgo² y varianza. D tiene mucho sesgo pero casi nada de varianza; con
muestras pequeñas la varianza de A pesa más. Al crecer n, la varianza de A baja y el sesgo de
D se queda.

**¿El experimento no favorece a A, si el valor de referencia es el propio A?**
Es una limitación reconocida. La simulación muestra que A converge al Theil ponderado de la
GEIH y cuánto se alejan de él los demás. Como la GEIH es una muestra probabilística con
pesos, ese es el objetivo correcto de estimación.

**¿Por qué no se rechaza H3 si el Theil bajó?**
Porque la caída (−0,010) es pequeña frente a la incertidumbre: el percentil 95 del bootstrap
es positivo (+0,0085), así que una caída de cero es compatible con los datos.

**¿Qué significa que la educación "explique" el 25 %?**
Que si todas las personas ganaran el promedio de su nivel educativo, quedaría un Theil igual
al 25 % del actual. Es una descomposición contable, no una relación causal.

**¿Qué es el ajuste por no respuesta?**
Repartir el peso de quien no reporta ingreso entre quienes sí lo reportan dentro de celdas
de personas parecidas. Así no se pierde población y el total se conserva.

**¿Por qué no se usa 2020?**
La encuesta fue telefónica por la pandemia: falta el ingreso de la mayoría y no se preguntó
el estrato.

**¿Por qué bootstrap y no una fórmula para el intervalo?**
El Theil no tiene una fórmula sencilla para su varianza, y menos su descomposición. El
bootstrap la aproxima con los datos, sin suponer normalidad.

**¿Por qué la prueba de H1 es pareada?**
Porque A y el competidor se calculan sobre la misma submuestra en cada réplica. Comparar
dentro de cada réplica elimina la variación debida a la muestra.

**¿Cuántas réplicas y por qué?**
500, tanto en la simulación como en el bootstrap. Es suficiente para que los percentiles y
los ECM sean estables, y el código corre en unos 10 minutos.

---

## Referencias

- Ariza, J., y Montes-Rojas, G. (2017). Labour income inequality and the informal sector in
  Colombian cities. *Cuadernos de Economía, 36*(72), 77–98.
- Cowell, F. A. (2011). *Measuring inequality* (3.ª ed.). Oxford University Press.
- Departamento Administrativo Nacional de Estadística. (2023). *Metodología general Gran
  Encuesta Integrada de Hogares – GEIH*. DANE.
- Departamento Administrativo Nacional de Estadística. (2025). *Pobreza monetaria en
  Colombia: año 2024* [Boletín técnico]. DANE.
- Departamento Administrativo Nacional de Estadística. (2026). *Gran Encuesta Integrada de
  Hogares – GEIH, 2018–2026* [Conjunto de datos]. DANE.
- Efron, B., y Tibshirani, R. J. (1993). *An introduction to the bootstrap*. Chapman & Hall.
- Mills, J. A., y Zandvakili, S. (1997). Statistical inference via bootstrapping for
  measures of inequality. *Journal of Applied Econometrics, 12*(2), 133–150.
- Sánchez-Torres, R. M. (2017). Desigualdad del ingreso en Colombia: un estudio por
  departamentos. *Cuadernos de Economía, 36*(72), 139–178.
- Shorrocks, A. F. (1980). The class of additively decomposable inequality measures.
  *Econometrica, 48*(3), 613–625.
- Theil, H. (1967). *Economics and information theory*. North-Holland.
