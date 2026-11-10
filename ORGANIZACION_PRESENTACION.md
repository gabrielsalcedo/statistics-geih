# Organización de la presentación del proyecto

*Para usar con `latex/beamer.tex`: 16 diapositivas de contenido más 2 de referencias.*
*Duración objetivo: 13 a 14 minutos, más preguntas.*

La presentación está dividida en **cuatro partes**, una por integrante.
- **Nadie está asignado todavía.** El equipo decide quién toma cada parte y escribe el
  nombre en la línea "Presenta".
- Cada parte tiene:
  - las diapositivas, el tiempo y el objetivo;
  - qué decir en cada diapositiva (guion sugerido, para decirlo con palabras propias, no
    para leerlo);
  - qué señalar en pantalla;
  - la frase para pasar la palabra;
  - lo que quien presenta debe dominar para las preguntas.

---

## Vista general

| Parte | Tema | Diapositivas | Tiempo | Presenta |
|---|---|---|---|---|
| 1 | Problema, pregunta e hipótesis | 1–4 | 2:30 | ______________ |
| 2 | Datos y método | 5–7 | 3:30 | ______________ |
| 3 | Descriptiva y simulación (H1) | 8–11 | 3:30 | ______________ |
| 4 | Desigualdad, pruebas y conclusiones | 12–16 | 3:30 | ______________ |
| — | Preguntas del jurado | 17–18 (referencias, de respaldo) | lo que pidan | Todos |

**Criterios que pueden servir para repartir las partes:**
- La **parte 2** le conviene a quien conozca mejor la GEIH, la depuración y el código.
- La **parte 3** le conviene a quien domine sesgo, ECM y la simulación.
- La **parte 4** le conviene a quien domine bootstrap y pruebas de hipótesis.
- La **parte 1** abre la presentación: le conviene a quien hable con más soltura frente al
  público.

---

## Parte 1 — Problema, pregunta e hipótesis

**Presenta:** ______________  **Diapositivas:** 1 a 4  **Tiempo:** ~2:30

**Objetivo de la parte:** que el público entienda por qué importa **cómo** se estima la
desigualdad, y qué vamos a responder.

### Diapositiva 1: Portada (0:15)
> "Buenos días. Somos [nombres] y les vamos a presentar: ¿Cómo estimar el índice de Theil con
> la GEIH? Comparamos cuatro estimadores y los usamos para medir la desigualdad del ingreso
> laboral en Colombia entre 2018 y 2026."

### Diapositiva 2: Contenido (0:15)
> "Primero el problema y la pregunta; luego los datos y el método; después los resultados y,
> al final, las conclusiones."

### Diapositiva 3: ¿Por qué importa cómo se estima la desigualdad? (1:00)
> "Colombia es uno de los países más desiguales de la región. Pero las cifras de desigualdad
> salen de encuestas: son estimaciones, no la desigualdad real. Con los mismos datos hay
> varias formas de estimar el índice de Theil, y si elegimos mal la fórmula, el resultado
> puede estar sesgado aunque tengamos muchísimos datos."

- **Señalar:** el bloque "Pregunta". Leer la pregunta completa en voz alta.

### Diapositiva 4: Hipótesis (1:00)
> "Tenemos tres hipótesis. H1: el estimador ponderado, A, es consistente y tiene el menor
> error cuando la muestra crece. H2: en 2026 la educación explica más desigualdad que las
> demás dimensiones. H3: la desigualdad fue menor en 2026 que en 2018. Todas las pruebas son
> unilaterales, con alfa de 0,05."

- **Para pasar la palabra:** "Para responder esto necesitamos datos y un método. [Nombre] nos
  cuenta cuáles."

**Debe dominar:**
- qué es un estimador y qué es el sesgo;
- por qué el Theil y no el Gini: se descompone exactamente entre/dentro;
- por qué las hipótesis son unilaterales.

---

## Parte 2 — Datos y método

**Presenta:** ______________  **Diapositivas:** 5 a 7  **Tiempo:** ~3:30

**Objetivo de la parte:** que el público sepa de dónde salen los datos, qué son los cuatro
estimadores y cómo los pusimos a prueba.

### Diapositiva 5: Datos de la GEIH (1:15)
> "Usamos la Gran Encuesta Integrada de Hogares del DANE, de enero a junio de cada año entre
> 2018 y 2026. 2020 no entra, porque la encuesta fue telefónica y falta el ingreso y el
> estrato. Trabajamos con ocupados de 15 años o más, remunerados, con ingreso positivo y en
> los 24 departamentos que la encuesta cubre todos los años. Son entre 130.000 y 161.000
> personas por año, que representan unos 21,6 millones de ocupados.
> Nuestra regla fue marcar, no borrar: guardamos a todos y marcamos quién cumple cada
> criterio. A quienes no reportan ingreso no los eliminamos: su peso se reparte entre
> personas parecidas que sí responden."

- **Señalar:** el bloque "En cifras" y los dos factores de expansión (cambio de marco en
  2022).

### Diapositiva 6: Cuatro estimadores (1:15)
> "El Theil vale cero cuando todos ganan lo mismo y crece cuando el ingreso se concentra.
> Los estimadores A y B aplican la fórmula directamente a la muestra: A con el factor de
> expansión, que dice a cuántas personas representa cada encuestado, y B sin él.
> C y D suponen que el ingreso es lognormal; en ese caso el Theil es sigma al cuadrado sobre
> dos. C estima sigma al cuadrado por momentos y D por máxima verosimilitud.
> Abajo está la descomposición: el Theil se separa exactamente en desigualdad entre grupos y
> dentro de los grupos."

- **Señalar:** la fórmula de A y luego el bloque de la descomposición.

### Diapositiva 7: Diseño del experimento y de la inferencia (1:00)
> "Para saber cuál estimador es mejor, hicimos una simulación Monte Carlo. Tomamos la GEIH
> 2024 completa como población; su Theil, 0,5043, es el valor de referencia. Sacamos 500
> submuestras para cada tamaño, de 500 a 50.000 personas, y en cada una calculamos los
> cuatro estimadores. Así medimos sesgo, varianza y error cuadrático medio.
> Para la parte aplicada usamos bootstrap: remuestreamos personas 500 veces para obtener
> intervalos de confianza y probar H2 y H3."

- **Para pasar la palabra:** "Antes de ver la simulación, miremos cómo es el ingreso.
  [Nombre]."

**Debe dominar:**
- qué es el factor de expansión y por qué ponderar (Bogotá es el 4,4 % de la muestra y el
  19,6 % de los ocupados);
- el ajuste por no respuesta: celdas, mínimo de 30 respondientes, total conservado;
- por qué D divide por n (máxima verosimilitud);
- por qué no se usa 2020 y qué cambió en 2022 (marco muestral).

---

## Parte 3 — Descriptiva y simulación (H1)

**Presenta:** ______________  **Diapositivas:** 8 a 11  **Tiempo:** ~3:30

**Objetivo de la parte:** mostrar que el ingreso no es lognormal y que solo A es
consistente.

### Diapositiva 8: Pico en el salario mínimo (0:50)
> "Este es el ingreso laboral en salarios mínimos. Hay un pico enorme en un salario mínimo: el
> 15,5 % gana alrededor de un mínimo y el 39,5 % gana menos. Es muy asimétrico: la media es
> 2,3 millones y la mediana 1,75 millones."

- **Señalar:** la línea roja en 1 SMMLV y la cola larga a la derecha.

### Diapositiva 9: ¿Es lognormal el ingreso? No (0:50)
> "Si el ingreso fuera lognormal, su logaritmo seguiría esta curva normal. No la sigue: hay un
> pico en el salario mínimo y colas más pesadas. Esto anticipa que C y D, que suponen
> lognormalidad, van a fallar."

- **Señalar:** dónde el histograma se separa de la curva roja.

### Diapositiva 10: Simulación, solo A es consistente (1:00)
> "Este gráfico muestra el error cuadrático medio de cada estimador según el tamaño de
> muestra, en escala logarítmica. El error de A baja sin parar. B y D se estancan: su sesgo
> no desaparece. Un detalle interesante: con muestras de 500, D tiene menos error que A,
> porque casi no varía aunque esté sesgado. Desde 10.000 personas, A gana."

- **Señalar:** la línea roja (A) bajando y las líneas de B y D planas.

### Diapositiva 11: Simulación con n = 50.000 (0:50)
> "Con 50.000 personas, el sesgo de A es prácticamente cero. B y D subestiman la desigualdad
> en cerca de un 15 % y C la sobreestima en cerca de un 5 %. El error de A es entre 4 y 24
> veces menor que el de los demás."

- **Para pasar la palabra:** "Con este resultado elegimos A para medir la desigualdad en
  Colombia. [Nombre] nos muestra qué encontramos."

**Debe dominar:**
- sesgo, varianza, ECM = sesgo² + varianza, y eficiencia relativa (ER < 1: A es mejor);
- por qué A subestima con n pequeño (los ingresos muy altos rara vez entran);
- el trade-off sesgo–varianza que explica el caso de n = 500;
- la limitación: el valor de referencia es el propio A sobre la GEIH 2024.

---

## Parte 4 — Desigualdad, pruebas y conclusiones

**Presenta:** ______________  **Diapositivas:** 12 a 16  **Tiempo:** ~3:30

**Objetivo de la parte:** presentar la desigualdad 2018–2026, qué la explica, la decisión
sobre cada hipótesis y las conclusiones.

### Diapositiva 12: Desigualdad 2018–2026 (0:50)
> "Con el estimador A, la desigualdad subió hasta 2022, cuando llegó a 0,538, y luego bajó
> cada año hasta 0,429 en 2026, el valor más bajo. Las barras son intervalos de confianza del
> 95 % por bootstrap. El salto de 2022 coincide con el cambio de marco muestral, así que
> parte puede ser metodológico."

- **Señalar:** 2022 (máximo), 2026 (mínimo) y que los intervalos de 2018 y 2026 se
  superponen.

### Diapositiva 13: ¿Qué explica la desigualdad? (0:50)
> "El estrato es lo que más explica: entre 31 y 38 % del Theil. Le siguen la educación y la
> formalidad, casi empatadas. La región explica poco y el sexo menos del 1 %. Y algo
> importante: la mayor parte de la desigualdad está dentro de los grupos, entre personas del
> mismo estrato o del mismo nivel educativo."

- **Señalar:** la línea del estrato arriba y las de educación y formalidad entrelazadas.

### Diapositiva 14: Pruebas de hipótesis (0:50)
> "H1 se cumple: la prueba t pareada rechaza la hipótesis nula frente a B, C y D, con valores
> p menores a 0,001. H2 no se cumple: la educación no supera a la formalidad ni al estrato.
> H3 tampoco: el Theil bajó 0,010 entre 2018 y 2026, pero el percentil 95 del bootstrap es
> positivo, así que la caída no es significativa."

### Diapositiva 15: Conclusiones (0:45)
> "Primero: con la GEIH hay que usar el estimador ponderado, porque es el único consistente.
> Segundo: la desigualdad bajó desde 2022, pero frente a 2018 la diferencia no es
> significativa. Tercero: el estrato es lo que más la explica. Como limitaciones: el valor
> de referencia es el propio A, el marco cambió en 2022, la no respuesta es mayor en estratos
> altos y el bootstrap ignora los conglomerados."

### Diapositiva 16: ¡Gracias! (0:05)
> "Muchas gracias. El código y los datos están en el repositorio. Quedamos atentos a sus
> preguntas."

**Debe dominar:**
- cómo funciona el bootstrap y los intervalos por percentiles;
- las reglas de decisión: H2 usa el percentil 5 de S*_edu − S*_k y H3 el percentil 95 de
  T*_2026 − T*_2018;
- por qué la prueba de H1 es pareada;
- qué significa "explicar" en la descomposición: es contable, no causal.

---

## Preguntas del jurado: cómo repartirlas

- **Regla:** responde quien presentó la parte relacionada con la pregunta. Si no sabe, otro
  integrante completa.
- Las diapositivas 17–18 (referencias) quedan de respaldo.

| Si preguntan sobre… | Responde quien presentó |
|---|---|
| Motivación, Theil frente a Gini, hipótesis | Parte 1 |
| GEIH, depuración, pesos, no respuesta, 2020, marco 2022, fórmulas de los estimadores | Parte 2 |
| Distribución del ingreso, simulación, sesgo, ECM, n = 500 | Parte 3 |
| Bootstrap, intervalos, H2, H3, descomposición, conclusiones, limitaciones | Parte 4 |
| Código, reproducibilidad, R | Quien lo conozca mejor (acordar antes) |

Las respuestas cortas a las preguntas más probables están en la sección 18 de
[`GUIA_PROYECTO.md`](GUIA_PROYECTO.md).

---

## Póster (70 × 100 cm)

Si hay una sesión de póster, conviene acordar:
- quién lo imprime y cuándo (el PDF sale de `latex/poster.tex`);
- el orden de explicación, que sigue el de las columnas:
  - **izquierda:** pregunta → hipótesis → datos → ingreso no lognormal → estimadores →
    simulación;
  - **derecha:** desigualdad → descomposición → pruebas → conclusiones;
- quién se queda junto al póster en cada turno: ______________.

---

## Lista de verificación antes del día

- [ ] Asignar las cuatro partes y escribir los nombres en este documento.
- [ ] Completar el Anexo C (roles) del informe con lo que hizo cada integrante.
- [ ] Ensayar completo con cronómetro, al menos dos veces: la meta es 13–14 minutos.
- [ ] Cada integrante repasa la sección "Debe dominar" de su parte y las preguntas
      probables.
- [ ] Llevar el PDF de la presentación en USB y en el correo; no depender de Overleaf en vivo.
- [ ] Revisar que el computador del salón abra el PDF en pantalla completa (16:9).
- [ ] Acordar quién cambia las diapositivas, o si cada quien cambia las suyas.

## Consejos

- **Señalen la figura** al hablar de ella ("aquí se ve…") y no lean las diapositivas.
- **Usen los números redondeados** al hablar (15 %, 0,43) y dejen los decimales para las
  preguntas.
- **Si una pregunta toca una limitación, reconózcanla** y expliquen qué harían para
  corregirla. Eso suma puntos.
- **Las transiciones importan:** cada parte termina anunciando la siguiente.
