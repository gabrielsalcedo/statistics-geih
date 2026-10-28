# Estado del proyecto — 16 de octubre de 2026

## 1. Qué está hecho

| Paso de la propuesta | Estado | Dónde |
|---|---|---|
| Bases anuales 2018–2026 (meses 1–6) | ✅ Hecho y verificado | `01_base_cruda_anual.R`, `02_base_analitica_anual.R` |
| Estadística descriptiva | ✅ Hecho | `04_estadistica_descriptiva.R`, `outputs/descriptiva/` |
| Theil A y descomposición entre/dentro (5 dimensiones, 8 años) | ✅ Hecho (adelantado; era del corte 3) | `03_theil.R`, `data/resultados/` |
| Estimador B (sin pesos) | ✅ Ya se calcula en `03_theil.R` (`peso = "sin_pesos"`) | |
| Revisión de lognormalidad (gráfica) | ✅ Figura `07b_ln_ingreso_vs_normal.png` | |
| Estimadores C y D | ❌ Falta programarlos | |
| **Experimento de simulación (eje del proyecto)** | ❌ Falta | |
| Prueba de H1 (t pareada sobre diferencias de pérdida) | ❌ Falta | |
| Bootstrap e intervalos de confianza | ❌ Falta | |
| Pruebas de H2 y H3 | ❌ Falta | |
| Informe y presentación | ❌ `report/` está vacío | |

## 2. Verificación del manejo de datos

- Enero de 2018 reconstruido desde los archivos crudos: Cabecera (24.952) + Resto (2.741) = 27.693 ocupados, igual a la base. El 100 % de Área está dentro de Cabecera, así que descartarla no pierde a nadie.
- 0 duplicados, 0 ocupados sin pareja al unir con características generales y con vivienda, 0 diferencias de FEX y DPTO entre módulos.
- La base analítica tiene las mismas filas, en el mismo orden, que la base cruda: no se borra a nadie, solo se marca.
- `fex_aj` conserva exactamente el total del FEX: el ajuste reparte el peso de quienes no reportan ingreso entre quienes sí lo reportan, dentro de la misma celda.

## 3. Correcciones al documento de la primera entrega

1. **Factor de expansión.** El documento dice que se usa el factor del Marco 2018 en todos los años. No es así: 2018–2021 usan `fex_c_2011` y 2022–2026 usan `FEX_C18`. Hay que corregir el texto y la Tabla 1, y añadirlo a las limitaciones.
2. **Meses.** El documento dice "enero–julio"; en realidad se usan los meses 1 a 6.
3. **Número de bases.** Son nueve bases, pero el Theil se calcula sobre ocho porque 2020 se excluye. Hay que explicar por qué.
4. **Regiones.** El documento lista seis regiones, pero con la cobertura común de 24 departamentos quedan cinco: Orinoquía-Amazonía y San Andrés no entran.
5. **Depuración incompleta.** Faltan los filtros de remunerados, cobertura común y dimensiones completas, y el ajuste por no respuesta. Sugerencia: poner la tabla de trazabilidad (`trazabilidad_<año>.csv`), que muestra que no se pierden datos sin explicación.
6. **Formalidad.** El documento dice "según su posición ocupacional", pero el código solo usa P6920 (cotiza o ya es pensionado). Hay que alinear las dos cosas.
7. **Tabla 1.** `RAMA2D_R4` no se extrajo; `P6500` y `P6750` sí se extrajeron pero no aparecen en la tabla.

## 4. Decisiones pendientes del equipo

- **Estrato faltante.** Cerca de 3.500 respondientes por año tienen estrato 0, 9 o vacío. Hoy se quedan por fuera de *todas* las dimensiones, no solo de estrato, y ganan en promedio la mitad que los demás. Por eso el Theil sale algo subestimado (2024: 0,498 → 0,504 con FEX). Opciones: crear una categoría "Sin estrato" o no exigir estrato en `f_dims`.
- **C y D con o sin pesos.** Tal como están escritos, C y D no usan pesos. Así, frente a A mezclan dos problemas: el de diseño (los pesos) y el de especificación (la lognormalidad). Si se calculan con pesos, la comparación aísla el supuesto lognormal, y B ya cubre el problema de los pesos.
- **H3 y el cambio de marco.** El Theil sube de 0,474 (2021) a 0,538 (2022), justo cuando cambian el marco y el factor. Comparar 2018 contra 2026 mezcla el cambio real con el cambio metodológico. Opción: contrastar 2022 contra 2026 (mismo marco) como prueba principal y dejar 2018 como referencia con advertencia.
- **Ingresos muy bajos.** Hay ingresos de 9 pesos y cientos por debajo de $50.000 al año. El estimador D (varianza de los logaritmos) es muy sensible a la cola baja. Hay que decidir y documentar una regla, o al menos reportar una prueba de sensibilidad.
- **Diseño de la simulación.** Una submuestra de 50.000 sobre unos 152.000 respondientes es un tercio de la "población". Sin reemplazo, la varianza baja más rápido que 1/n (corrección por población finita). Hay que decidir: con reemplazo, o reportarlo.
- **Bootstrap por vivienda.** Remuestrear `DIRECTORIO` en lugar de personas respeta en parte los conglomerados y cuesta lo mismo.

## 5. Conexión con los temas del curso

| Tema del curso | Dónde aparece en el proyecto |
|---|---|
| Estimadores puntuales: sesgo, varianza, ECM, eficiencia relativa | Simulación (paso 4) |
| Consistencia | ECM vs. n en los cuatro tamaños de muestra |
| Método de momentos | Estimador C |
| Máxima verosimilitud y suficiencia | Estimador D (Σ ln y, Σ (ln y)²) |
| Distribución muestral y TLC | Histogramas de las 500 réplicas de cada estimador |
| Bondad de ajuste | ln(ingreso) vs. normal. Con n ≈ 150.000 cualquier prueba rechaza, así que conviene usar QQ-plot y una submuestra (Shapiro-Wilk en R admite máximo 5.000 datos) |
| Pruebas de hipótesis (t pareada, unilateral) | H1 |
| Intervalos de confianza / bootstrap | H2, H3 e IC de cada Theil |
| Estadística descriptiva ponderada | Paso 2 (ya hecho) |
