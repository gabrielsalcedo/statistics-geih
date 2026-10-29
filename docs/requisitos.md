# Requisitos del curso — checklist

Fuente: `docs/curso/parametros proyecto.pdf` (Anexo 1, guía del proyecto y rúbrica).
Estado al 28-10-2026, revisado contra el código (rama `revision-general`) y la entrega
vigente (`docs/curso/report/primera_entrega_corregida.tex`).

Leyenda: ✅ cumplido · 🟡 parcial · ❌ pendiente

## Base de datos (cortes 1 y 2)

| Requisito | Estado | Evidencia / qué falta |
|---|---|---|
| Al menos 3 variables cuantitativas, 1 de ellas continua | ✅ | `ingreso` (continua, razón), `edad` y `horas` (discretas, razón). Están en la base final (`data/processed/`, `data/codebook.md`) |
| Al menos 2 variables cualitativas | ✅ | `sexo`, `formal`, `region`, `posicion` (nominales); `educ`, `estrato`, `tam_empresa` (ordinales) |
| Decisiones sobre los valores perdidos | ✅ | La no respuesta de ingreso se ajusta con pesos (`fex_aj`); las dimensiones faltantes se excluyen con `f_dims`. Documentado en la entrega y en `docs/AUDITORIA.md` §2.4. Falta mencionar en el texto las decisiones abiertas D1 y D9 |
| Base estructurada y normalizada | ✅ | Una fila por persona y mes, llaves verificadas, 30 columnas iguales en los 9 años |
| Tipo de variable y escala de medición | ✅ | Tabla 1 de la entrega, `data/analitica/diccionario_variables.csv`, `data/codebook.md` |
| ¿Muestra o población? ¿De dónde se obtuvo? | ✅ | Muestra probabilística de la GEIH (DANE), citada |
| Tipo de muestreo y tamaño | 🟡 | La entrega dice "probabilística". Falta decir que es estratificada, multietápica y por conglomerados, y explicar por qué eso obliga a usar el factor de expansión |

## Planteamiento (corte 2)

| Requisito | Estado | Evidencia / qué falta |
|---|---|---|
| Portada con título | ✅ | Entrega |
| Contenido (índice) | ❌ | La entrega no tiene tabla de contenido |
| Planteamiento del problema | ✅ | Sección "Justificación" |
| Objetivo general y específicos | ✅ | Sección "Objetivos" |
| Pregunta de investigación | ✅ | Sección "Pregunta problema" |
| Hipótesis de investigación | ✅ | H1, H2, H3 |
| Población | ✅ | Definida en "Depuración" |
| Marco metodológico | 🟡 | Hay estimadores y depuración. Falta el diseño de la simulación (decisión D5) y el plan de análisis inferencial |
| Revisión bibliográfica: mínimo 4 referentes, mínimo 2 páginas, APA | 🟡 | 10 referencias citadas, en APA 7 con `biblatex`. "Estado del arte" + "Resumen de artículos" parecen menos de 2 páginas: hay que verificar la extensión en el PDF |

## Análisis descriptivo (corte 2)

| Requisito | Estado | Evidencia / qué falta |
|---|---|---|
| Tablas de frecuencias y gráficas univariadas (barras, histogramas, cajas), interpretadas | 🟡 | Las genera `04_estadistica_descriptiva.R` (tablas 02–03, figuras 03, 07a). **No están en la entrega ni interpretadas en el texto.** Falta la frecuencia de `tam_empresa` |
| Tablas cruzadas y gráficas bivariadas, interpretadas | 🟡 | Tablas 04 (educ×formal, sexo×formal, región×formal, estrato×educ), boxplots por grupo y dispersión horas–ingreso. Falta la interpretación en el texto |
| Medidas de tendencia central, localización, variabilidad y forma de cada variable | 🟡 | Tabla 01 para ingreso, ln(ingreso), edad y horas: media, mediana, moda, cuantiles, DE, CV, asimetría y curtosis. Faltan interpretaciones y una medida descriptiva para cada cualitativa (moda, proporciones) |
| Ponderadas por el factor de expansión | ✅ | Todo con `fex_aj`. El código lo dice; **el texto también debe decirlo** |
| Todo en R | ✅ | |

## Inferencia (corte 3)

| Requisito | Estado | Evidencia / qué falta |
|---|---|---|
| Al menos un intervalo de confianza | ❌ | No hay ninguno. El bootstrap de H2/H3 no está programado |
| Al menos una prueba de hipótesis | ❌ | No hay ninguna. H1 (t pareada) depende de la simulación, que no existe |
| Procedimientos **clásicos** del curso (z, t, F, χ²) y no solo bootstrap | ❌ | Lo único clásico previsto es la t pareada de H1, y es sobre réplicas simuladas. Propuestas en `docs/alineacion_curso.md` |
| Simulación Monte Carlo | ❌ | No existe (ver `docs/AUDITORIA.md` §3.3–3.5) |
| Regresión simple con pruebas de los parámetros y supuestos | ❌ | Solo hay una recta descriptiva en la figura de dispersión |
| Pruebas no paramétricas | ❌ | No hay ninguna (opcional según la guía) |

## Entregables finales (corte 3)

| Requisito | Estado | Evidencia / qué falta |
|---|---|---|
| Informe final: análisis de máximo 10 páginas | ❌ | No existe `report/`. Ver el presupuesto de páginas en `docs/alineacion_curso.md` |
| Times New Roman o Arial, 12 pt | ❌ | La entrega usa Latin Modern (`lmodern`). Hay que cambiar a Times (`\usepackage{newtx}`) o Arial |
| Interlineado 1,5 | ❌ | La entrega usa `\doublespacing`. La guía dice "1.5 centímetros", lo que casi seguro significa 1,5 líneas. Conviene confirmarlo con el profesor |
| Estilo de informe ejecutivo / técnico | ❌ | |
| Presentación oral | ❌ | No existe `slides/` |
| Póster 70 × 100 cm | ❌ | No existe `poster/` |
| Rúbrica: Introducción | 🟡 | Existe en la entrega |
| Rúbrica: Datos, figuras, tablas | 🟡 | Generados en R; falta incluirlos con `\input{}` e `\includegraphics{}` |
| Rúbrica: Discusión | ❌ | |
| Rúbrica: Conclusiones | ❌ | |
| Rúbrica: Bibliografía | ✅ | `references.bib`, APA 7 |
| Rúbrica: análisis descriptivo de las variables en el informe final | 🟡 | Ver la sección de análisis descriptivo |
| Roles y responsabilidades de cada integrante | ❌ | La rúbrica lo evalúa. Conviene una tabla en el informe o en el README |
