# Alineación del proyecto con el curso

Qué temas del curso usa el proyecto, dónde y qué falta. Las sesiones son las que indicó
Gabriel; el programa del curso con las sesiones no está en `docs/curso/`, así que conviene
agregarlo para confirmar los números. Estado al 28-10-2026.

## 1. Tabla de alineación

| Tema / requisito | Sesión | ¿Cubierto? | Dónde | Qué falta |
|---|---|---|---|---|
| Tipos de variables y escalas | 1–6 | ✅ | `data/codebook.md`, Tabla 1 de la entrega | — |
| Tablas de frecuencias y gráficas univariadas | 1–6 | 🟡 | `06_descriptiva.R`: tablas 02–03, figuras 03 y 07a | Interpretación en el texto; frecuencia de `tam_empresa` |
| Tablas cruzadas y gráficas bivariadas | 1–6 | 🟡 | Tablas 04, figuras 04 y 05 | Interpretación en el texto |
| Tendencia central, posición, dispersión y forma | 1–6 | 🟡 | Tabla 01 (ponderada) | Interpretación; moda y proporciones de las cualitativas |
| Valores atípicos | 1–6 | 🟡 | `AUDITORIA.md` §2.6 (ingresos de $1, más de 100 horas) | Llevarlo a la descriptiva: regla del boxplot (1,5·RIC) y decisión D4 |
| Parámetro, estimador, sesgo, varianza, ECM | 7–14 | ❌ | Diseñado (H1) | La simulación no existe |
| Consistencia | 7–14 | ❌ | Diseñado: ECM frente a n | Simulación |
| Eficiencia relativa | 7–14 | ❌ | Diseñado: ER = ECM(A)/ECM(j) | Simulación |
| Método de momentos | 7–14 | 🟡 | `theil_C()` en `R/theil.R` | Usarlo en la simulación; explicar la derivación en el texto |
| Máxima verosimilitud y suficiencia | 7–14 | 🟡 | `theil_D()` (divisor n) | Igual que C; mostrar Σ ln y y Σ (ln y)² como estadísticos suficientes |
| Distribución muestral y TLC | 7–14 | ❌ | — | Histograma de las 500 réplicas de cada estimador en n = 50.000 |
| IC para una media (t) | 15–18 | ❌ | — | **Propuesta P1** |
| IC para una proporción (z) | 15–18 | ❌ | — | **Propuesta P2** |
| IC por bootstrap | 15–18 | ❌ | Diseñado para H2 y H3 | Programarlo (decisión D6) |
| Prueba t para una media / diferencia de medias | 19–25 | ❌ | — | **Propuesta P3** |
| Prueba t pareada | 19–25 | ❌ | Diseñada para H1 | Depende de la simulación |
| Prueba F de razón de varianzas | 19–25 | ❌ | — | **Propuesta P4** |
| Errores tipo I y II, potencia, valor p | 19–25 | ❌ | — | Discutirlos con P3 y H1: con n grande todo es significativo |
| Regresión lineal simple: estimación, pruebas de β, R² | 26–27 | ❌ | Solo una recta descriptiva en la figura 05 | **Propuesta P6** |
| Supuestos de los residuos | 26–27 | ❌ | — | P6: QQ-plot, residuos frente a ajustados, Breusch-Pagan |
| Chi-cuadrado de independencia | 28 | ❌ | — | **Propuesta P5** |
| Bondad de ajuste | 28 | 🟡 | Figura 07b (histograma frente a la normal) | **Propuesta P7**: QQ-plot + Shapiro sobre una submuestra |
| Pruebas no paramétricas | — | ❌ | — | P4 incluye Brown-Forsythe como alternativa robusta a F (opcional) |
| Simulación Monte Carlo | 29–31 | ❌ | Diseño en `AUDITORIA.md` §3.4–3.5 | Es el eje del proyecto: falta todo (decisión D5) |

## 2. Propuestas para cerrar los vacíos (no implementadas)

Usan solo variables que ya están en `data/processed/`. Corrí todas en borrador sobre 2026
para comprobar que funcionan; los números de abajo son de ese piloto.

### Cómo aplicar pruebas clásicas a la GEIH

Las pruebas del curso suponen una muestra aleatoria simple. La GEIH no lo es: tiene pesos y
conglomerados, y con n ≈ 155.000 cualquier diferencia, por pequeña que sea, resulta
significativa. Con la base completa, la t de formal contra informal da p = 0, lo que no
informa nada.

Propuesta: hacer las pruebas clásicas sobre **una submuestra de n = 2.000 sacada con
probabilidad proporcional a `fex_aj`** (con semilla fija).
- Esa submuestra representa a la población de ocupados, como si fuera una muestra aleatoria
  simple de Colombia. Así las fórmulas del curso se aplican tal cual, sin pesos.
- El tamaño hace que las pruebas tengan potencia razonable sin que todo salga significativo.
- Es la misma lógica que ya usa la figura de dispersión de `04` y la que se recomienda para
  Shapiro-Wilk.
- El informe debe decir que es una aproximación que ignora los conglomerados. Hacerlo
  completo con el paquete `survey` sería más riguroso, pero agrega una dependencia y es más
  difícil de explicar.

| # | Análisis | Sesión | Variables | Piloto 2026 (n = 2.000) | Para qué sirve en el proyecto |
|---|---|---|---|---|---|
| P1 | IC del 95 % para la media de ln(ingreso), por año | 15–18 | `ingreso` | [14,18; 14,26] | Describe el nivel del ingreso con incertidumbre |
| P2 | IC del 95 % (z) para la proporción de informales | 15–18 | `formal` | 0,510 [0,489; 0,532] (ponderado en la base completa: 0,506) | Contexto de la descomposición por formalidad |
| P3 | t de Welch unilateral: H₀: μ_formal ≤ μ_informal en ln(ingreso) | 19–25 | `ingreso`, `formal` | diferencia = 1,07 (los formales ganan ≈ 2,9 veces más), t = 32,2, p < 10⁻¹⁰⁰ | Respalda el componente "entre" de la formalidad |
| P4 | F de razón de varianzas de ln(ingreso), formal / informal (+ Brown-Forsythe) | 19–25 | `ingreso`, `formal` | Var = 0,32 contra 0,79; F = 0,41, p < 10⁻⁴⁰. Brown-Forsythe: F = 129,7 | **Conecta con el proyecto:** Var(ln y) es la medida de desigualdad que estima D. Prueba que la desigualdad *dentro* del sector informal es mayor. F supone normalidad de ln y, que falla (P7); por eso conviene reportar también Brown-Forsythe, que es ANOVA sobre \|y − mediana\| con R base |
| P5 | χ² de independencia formalidad × educación, con V de Cramér | 28 | `formal`, `educ` | χ² = 509, gl = 4, p < 10⁻¹⁰⁰; V = 0,51; ninguna esperada < 5 | Muestra que las dimensiones están correlacionadas: los "entre" de formalidad y educación se solapan (limitación de H2) |
| P6 | Regresión simple ln(ingreso) ~ horas, con prueba de β₁ y supuestos | 26–27 | `ingreso`, `horas` | β₁ = 0,025 (cada hora semanal más ≈ +2,5 %), t = 17,1, R² = 0,13. Residuos no normales (Shapiro p ≈ 10⁻¹⁸) y heterocedásticos (Breusch-Pagan p ≈ 10⁻⁸) | Cumple el tema de regresión. Los supuestos fallan, y eso se reporta y se discute: los EE clásicos son aproximados |
| P7 | Bondad de ajuste de ln(ingreso) 2024: histograma + QQ-plot, y Shapiro-Wilk sobre una submuestra ∝ peso | 28 | `ingreso` | Asimetría −0,52, curtosis en exceso 2,30. El 15,4 % gana exactamente 1 SMMLV. Shapiro (n = 5.000): W = 0,954, p < 10⁻¹⁵. Rechaza en el 100 % de las submuestras aun con n = 200 | Justifica por qué C y D deberían fallar. **La gráfica va primero; la prueba es un complemento** |

**Alternativa para P6.** Una regresión ln(ingreso) ~ años de educación sería más
interesante (es la ecuación de Mincer), pero la base no tiene años de educación: solo los
5 niveles. Agregarla exige extraer el último grado aprobado (`P6210S1` / `P3042S1`) en
`01_base_cruda.R`. Eso cambia la limpieza y requiere aprobación.

**Notas:**
- En P3 a P5, el valor p sale prácticamente 0 incluso con n = 2.000. Lo importante es el
  tamaño del efecto (la diferencia, la razón de varianzas, V de Cramér), y el texto debe
  decirlo. Así se cubre el tema de error tipo I, potencia y valor p.
- Las siete propuestas caben en una tabla de media página en el informe. El detalle va
  en un anexo.
- Dónde irían: un script nuevo `scripts/07_inferencia_clasica.R` y la semilla y el n de la
  submuestra en `R/config.R`.

## 3. ¿Cabe todo en 10 páginas?

No cabe todo en el cuerpo. Presupuesto sugerido (12 pt, interlineado 1,5, figuras a media
página):

| Sección | Páginas | Contenido |
|---|---|---|
| Introducción, problema, objetivos e hipótesis | 1 | Versión corta de la entrega |
| Datos y métodos (población, pesos, estimadores, diseño de la simulación) | 1,5 | 1 tabla de estimadores |
| Descriptiva | 2 | 1 tabla de medidas, 1 figura (distribución + QQ), 1 figura de ingreso por grupo |
| Simulación (H1) | 2 | 1 tabla de sesgo / ECM / ER y 1 figura de ECM frente a n |
| Aplicación: Theil 2018–2026 y descomposición (H2, H3) | 1,5 | 1 figura de la serie con IC y 1 de las participaciones "entre" |
| Inferencia clásica (P1–P7) | 1 | 1 tabla resumen |
| Discusión, limitaciones y conclusiones | 1 | Incluye la sensibilidad de H3 (`AUDITORIA.md` §2.8) |
| **Total** | **10** | |

**A los anexos:** trazabilidad por año (Tabla 2), libro de códigos, tablas completas de
frecuencias y cruzadas, descomposición por grupo de todos los años, detalle de las
pruebas clásicas, sensibilidad a la no respuesta y al estrato faltante, y diagnóstico de
las celdas del ajuste.
