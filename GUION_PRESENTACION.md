# Guion de la presentación

**Proyecto:** ¿Qué estimador del índice de Theil usar con la GEIH?
**Presentación:** `latex/beamer.tex` (10 diapositivas).
**Duración estimada:** unas 1.800 palabras, que son 14 minutos hablados a 130 palabras por minuto. Con las pausas y los cambios de turno, entre 16 y 17 minutos, dentro del límite de 20.
**Reparto:** 4 personas y 8 turnos. Cada persona habla dos veces.

| Turno | Persona | Diapositivas | Tema | Tiempo |
|---|---|---|---|---|
| 1 | Persona 1 | 1–2 | El problema, la pregunta y las hipótesis | 2:00 |
| 2 | Persona 2 | 3 | Los datos y el muestreo | 2:00 |
| 3 | Persona 3 | 4 | Los seis estimadores | 2:00 |
| 4 | Persona 4 | 5 | Los dos supuestos que fallan | 2:00 |
| 5 | Persona 1 | 6 | Lo que predice la teoría | 2:00 |
| 6 | Persona 2 | 7–8 | El experimento Monte Carlo y su resultado | 3:00 |
| 7 | Persona 3 | 9 | La prueba de hipótesis y el intervalo de confianza | 2:30 |
| 8 | Persona 4 | 10 | Conclusiones y cierre | 2:00 |

> **Cómo usar este guion:** no hay que leerlo palabra por palabra. Cada turno tiene una idea central
> (en negrita al inicio); lo demás es una guía para decirla con naturalidad. Las frases de transición
> sí conviene aprenderlas, porque son las que hacen que la presentación se sienta como una sola.

---

## Turno 1 · Persona 1 · Diapositivas 1 y 2 (2:00)

**Idea central: una cifra de desigualdad depende de cómo se calcula.**

*(Diapositiva 1)*
> Buenos días. Somos [nombres], y les vamos a presentar nuestro proyecto: ¿qué estimador del índice
> de Theil se debe usar con la Gran Encuesta Integrada de Hogares?

*(Diapositiva 2)*
> Empecemos con un dato. En 2024, el Gini de Colombia fue 0,551: somos uno de los países más
> desiguales de América Latina. Pero esa cifra no se observa directamente: sale de una encuesta.
> Es una estimación. Y con los mismos datos se puede calcular de varias formas. Si se elige mal la
> forma, el error no aparece en ninguna parte: la cifra se publica igual.
>
> Nosotros trabajamos con el índice de Theil. Vale cero si todos ganan lo mismo y crece a medida que
> el ingreso se concentra. Lo elegimos porque es la medida que se puede separar en desigualdad entre
> grupos y dentro de ellos, y por eso es la más usada para estudiar sus causas.
>
> Nuestra pregunta es esta: de seis formas de estimar el Theil, ¿cuál funciona mejor con la GEIH, y
> en qué condiciones cambia la respuesta? Para contestarla planteamos dos hipótesis sobre el
> estimador que llamamos A, el que usa los factores de expansión. La primera, H1a: con muestras
> grandes, A se equivoca menos que los otros cinco. La segunda, H1b: A es el único que se acerca al
> valor verdadero a medida que crece la muestra.

**Transición:**
> Para ponerlas a prueba necesitábamos datos. [Persona 2] les cuenta con cuáles trabajamos.

---

## Turno 2 · Persona 2 · Diapositiva 3 (2:00)

**Idea central: la GEIH es una muestra compleja, y cada persona trae un peso.**

> Usamos los microdatos de la GEIH del DANE, de enero a junio de 2024. Es la única fuente en
> Colombia que tiene a la vez el ingreso laboral y los factores de expansión.
>
> Un punto clave es el tipo de muestreo. La GEIH no es un muestreo aleatorio simple: es
> probabilístico, estratificado, por conglomerados y en varias etapas. Primero se eligen municipios,
> luego zonas, luego viviendas. Por eso cada persona tiene una probabilidad distinta de ser
> encuestada, y trae un factor de expansión, que dice a cuántas personas del país representa.
>
> De 178.204 ocupados quedaron 152.213: personas de 15 años o más, con trabajo remunerado, en los
> 24 departamentos que la encuesta cubre todos los años y con ingreso positivo. Representan a unos
> 20,3 millones de ocupados. Trabajamos con 10 variables: cuatro cuantitativas en escala de razón,
> como el ingreso, la edad y las horas, y seis cualitativas, entre ellas la región, el estrato y la
> educación.
>
> Miren el ingreso, a la derecha. La media es 1,81 millones, pero la mediana es 1,3 millones, justo
> el salario mínimo. El coeficiente de variación es del 151 % y la asimetría es casi 10. Es decir:
> la mayoría gana cerca del mínimo, y unos pocos ingresos muy altos jalan la media hacia arriba.
> Todo este análisis se hizo en R.

**Transición:**
> Con esta base se puede calcular el Theil de varias formas. [Persona 3] nos explica las seis que
> comparamos.

---

## Turno 3 · Persona 3 · Diapositiva 4 (2:00)

**Idea central: cada estimador necesita algo distinto para acertar.**

> Comparamos seis estimadores, y la tabla resume lo más importante: qué necesita cada uno para dar
> el valor correcto.
>
> A aplica la fórmula del Theil a la muestra usando los factores de expansión. No necesita ningún
> supuesto. B es la misma fórmula, pero sin pesos: todos los encuestados cuentan igual. B solo
> acierta si la probabilidad de ser encuestado no tiene nada que ver con el ingreso.
>
> C y D toman otro camino. Suponen que el ingreso sigue una distribución lognormal. Si eso fuera
> cierto, el Theil sería simplemente la varianza del logaritmo dividida entre dos. C la estima por el
> método de momentos, a partir del coeficiente de variación, y D por máxima verosimilitud. Si el
> modelo fuera cierto, D sería el más preciso de todos, porque alcanza la cota de Cramér-Rao.
>
> El problema es que C y D tampoco usan pesos. Entonces pueden fallar por dos razones a la vez: por
> no ponderar o por suponer un modelo equivocado. Para separar esas dos razones agregamos Cw y Dw,
> que son C y D con pesos. Así, si comparamos C con Cw vemos el efecto de no ponderar, y si
> comparamos Cw con el valor verdadero vemos el efecto del modelo.

**Transición:**
> Entonces la pregunta es si en la GEIH se cumplen esos supuestos. [Persona 4] nos muestra que no se
> cumple ninguno.

---

## Turno 4 · Persona 4 · Diapositiva 5 (2:00)

**Idea central: en la GEIH fallan los dos supuestos.**

> El primer supuesto es que el diseño no es informativo, es decir, que la probabilidad de ser
> encuestado no tiene relación con el ingreso. La gráfica compara, en cada región, el porcentaje de
> la muestra con el porcentaje de la población. Miren Bogotá: es el 4,3 % de los encuestados, pero
> el 20,3 % de los ocupados del país. Y Bogotá es la región más rica: el 11,4 % gana cuatro salarios
> mínimos o más, frente al 2,3 % en el Caribe. La región menos representada en la muestra es justo
> la de mayores ingresos. Eso es un diseño informativo, y por eso un cálculo sin pesos mide la
> desigualdad de los encuestados, no la del país.
>
> El segundo supuesto es la lognormalidad. Si el ingreso fuera lognormal, su logaritmo sería normal.
> No lo es: tiene un pico muy alto en el salario mínimo y una cola izquierda larga. La asimetría es
> −0,52 y la curtosis en exceso es 2,30, cuando en una normal las dos serían cero. Hay una prueba
> todavía más directa: si el modelo fuera cierto, las dos formas de estimar la varianza darían lo
> mismo. Una da 1,184 y la otra 0,964.

**Transición:**
> Si los dos supuestos fallan, ¿cuánto se equivoca cada estimador? [Persona 1] retoma para mostrar
> que eso se puede calcular antes de simular.

---

## Turno 5 · Persona 1 · Diapositiva 6 (2:00)

**Idea central: la teoría predice cuánto se equivoca cada estimador.**

> Cuando la muestra es muy grande, cada estimador termina dando lo mismo que su fórmula aplicada a
> toda la base. Así podemos saber, sin simular, a qué valor llega cada uno. El valor verdadero es
> 0,5043, y la gráfica muestra cuánto se aleja cada estimador en porcentaje.
>
> B y D quedan un 15 % por debajo, y en ambos casos la causa principal es no usar los pesos. C sale
> con solo +4,7 %, y uno pensaría que está bien. Pero no: es la suma de dos errores grandes que se
> cancelan, −0,064 por no ponderar y +0,088 por el modelo. Acierta por casualidad. Las versiones
> ponderadas, Cw y Dw, solo tienen el error del modelo: +17 % y −4 %. Y A no tiene sesgo.
>
> Lo importante es que estos sesgos no dependen del tamaño de la muestra: más datos no los corrigen.

**Transición:**
> Pero esto es lo que dice la teoría. Para comprobarlo hicimos un experimento, y [Persona 2] nos
> cuenta cómo funcionó.

---

## Turno 6 · Persona 2 · Diapositivas 7 y 8 (3:00)

**Idea central: en una población donde conocemos la verdad, solo el error de A llega a cero.**

*(Diapositiva 7)*
> Con datos reales nunca se conoce el valor verdadero, así que no se puede medir el sesgo. Por eso
> construimos una población artificial: cada uno de los 152.213 registros representa a tantas
> personas como indica su factor de expansión. En esa población sí conocemos el Theil: 0,5043.
>
> De ella sacamos 500 muestras de cada uno de siete tamaños, desde 500 hasta 50.000 personas, y en
> cada muestra calculamos los seis estimadores. Con las 500 estimaciones medimos el sesgo, la
> varianza y el error cuadrático medio, que es el sesgo al cuadrado más la varianza.
>
> Lo hicimos en cuatro escenarios: con el ingreso real o con uno lognormal, y con un diseño
> informativo como el de la GEIH o con muestreo aleatorio simple. La tabla muestra qué estimadores
> resultaron consistentes en cada uno, y coincide en los 24 casos con lo que predecía la teoría. En
> el escenario de la GEIH, que está en rojo, solo A es consistente.

*(Diapositiva 8)*
> Esta gráfica es el resultado central. Muestra el error de cada estimador a medida que crece la
> muestra, en el escenario de la GEIH. La línea roja gruesa es A: su error baja todo el tiempo, y su
> sesgo pasa de −6,9 % con 500 personas a −0,2 % con 50.000.
>
> B y D, en cambio, se aplanan: tienen poca varianza, pero apuntan al valor equivocado, y por más
> datos que se agreguen no mejoran. El caso interesante es Dw, la línea azul. Como trabaja con el
> logaritmo, es muy estable, y con muestras pequeñas se equivoca menos que A. Solo al final, cerca
> de 32.000 personas, A lo supera.

**Transición:**
> Ahora, que A se vea mejor en la gráfica no basta: hay que probar que la diferencia es real.
> [Persona 3] nos muestra la prueba de hipótesis.

---

## Turno 7 · Persona 3 · Diapositiva 9 (2:30)

**Idea central: la prueba t pareada confirma que A se equivoca menos, y el intervalo lo cuantifica.**

> Para H1a usamos una prueba t pareada. En cada una de las 500 réplicas restamos el error al
> cuadrado de A menos el error al cuadrado del competidor. Si esa diferencia es negativa, en esa
> muestra A quedó más cerca del valor verdadero. Su promedio es justamente la diferencia de errores
> cuadráticos medios.
>
> ¿Por qué pareada? Porque A y su competidor se calculan sobre la misma muestra. Si a una muestra le
> tocan muchos ingresos altos, los dos se equivocan a la vez, y al restar eliminamos esa variación
> común. Así la prueba es más precisa.
>
> La hipótesis nula es que A no se equivoca menos. Con 50.000 personas la rechazamos frente a los
> cinco competidores, con valores p menores que 0,001. Los intervalos de confianza del 95 % quedan
> completos por debajo de cero, así que la ventaja es clara. Frente a D, A gana en el 100 % de las
> réplicas. El rival más cercano es Dw: A gana en el 72,6 % de las réplicas. Pero ojo, con muestras
> más pequeñas no es así: A le gana a Dw solo desde unas 32.000 personas.
>
> Para H1b usamos una prueba t de una muestra que compara el promedio de cada estimador con el valor
> verdadero. El sesgo de A es de −0,0011, y no se distingue de cero: p igual a 0,22. El de los otros
> cinco sí, con p menor que 0,001. Así que las dos hipótesis se cumplen: A es el único consistente.

**Transición:**
> Con esto ya podemos responder la pregunta. [Persona 4] cierra con las conclusiones.

---

## Turno 8 · Persona 4 · Diapositiva 10 (2:00)

**Idea central: con la GEIH hay que usar A, y siempre hay que validar cómo se calcula una cifra.**

> Tres conclusiones. Primera: con la GEIH hay que usar el estimador ponderado A. Es el único que
> acierta cuando el diseño es informativo y el ingreso no es lognormal, que es exactamente la
> situación de la GEIH.
>
> Segunda: cada estimador falla justo donde fallan sus supuestos. Ignorar los pesos subestima la
> desigualdad un 15 %, y suponer lognormalidad la desvía entre −4 % y +17 %. Y más datos no
> corrigen esos errores.
>
> Tercera: la respuesta depende del tamaño de muestra. Con menos de unas 32.000 personas, que es lo
> que tiene cada departamento, Dw se equivoca menos. Pero su sesgo puede ser positivo o negativo, y
> no hay forma de saberlo con una sola muestra.
>
> Nuestro trabajo tiene límites: la población simulada es la misma GEIH, y nuestro muestreo no
> reproduce los estratos ni los conglomerados. Aun así, la lección es clara: antes de reportar una
> cifra de desigualdad hay que validar cómo se calcula. La teoría dice qué puede fallar, la
> simulación dice cuánto y la prueba de hipótesis dice si la diferencia es real.
>
> Muchas gracias. Quedamos atentos a sus preguntas.

---

## Preguntas probables del jurado

Cada persona responde preferiblemente las preguntas de su parte.

**Persona 1 (problema, hipótesis y teoría)**
| Pregunta | Respuesta corta |
|---|---|
| ¿Por qué el Theil y no el Gini? | Porque el Theil se separa exactamente en desigualdad entre grupos y dentro de ellos; si su estimador está sesgado, todas esas descomposiciones también. |
| ¿Qué es el "límite" de un estimador? | El valor al que llega con una muestra muy grande: su fórmula aplicada a toda la base. |
| ¿Por qué C parece bueno? | Porque dos errores grandes de signo contrario se cancelan. Es un acierto por casualidad. |

**Persona 2 (datos y Monte Carlo)**
| Pregunta | Respuesta corta |
|---|---|
| ¿Qué es el factor de expansión? | A cuántas personas del país representa cada encuestado; es aproximadamente el inverso de su probabilidad de inclusión. |
| ¿Por qué quitaron los ingresos cero? | C y D usan el logaritmo, y el logaritmo de 0 no existe. Así los seis se calculan sobre la misma población. |
| ¿Qué pasa con quien no reporta ingreso? | No se borra: su peso se reparte entre personas parecidas que sí responden, y el total se conserva. |
| ¿No es circular usar la GEIH como población? | No: el experimento evalúa si cada estimador recupera, desde muestras, el valor de una población conocida. El supuesto es que los pesos describen bien al país. |

**Persona 3 (estimadores y pruebas)**
| Pregunta | Respuesta corta |
|---|---|
| ¿Por qué una prueba pareada y no de muestras independientes? | Los dos estimadores se calculan sobre la misma muestra y sus errores están correlacionados. Con n = 500, la pareada da t = −5,95 frente a −2,74 de la independiente. |
| ¿Y si d no es normal? | Las 500 réplicas son independientes, así que su media es aproximadamente normal por el teorema del límite central. |
| ¿Por qué no corrigen por comparaciones múltiples? | Porque exigimos rechazar frente a los cinco a la vez, no solo frente a alguno. |
| Con 500 réplicas todo sale significativo, ¿no? | Por eso también reportamos el tamaño del efecto: la eficiencia relativa y el porcentaje de réplicas en que gana A. |

**Persona 4 (supuestos y conclusiones)**
| Pregunta | Respuesta corta |
|---|---|
| ¿Qué es un diseño informativo? | Que la probabilidad de ser encuestado está relacionada con lo que se mide. En la GEIH, Bogotá está submuestreada y es la región más rica. |
| ¿Por qué no usar Dw, si se equivoca menos con muestras pequeñas? | Porque su sesgo cambia de signo entre años: no se sabe si sobrestima o subestima. A, con su intervalo, es más defendible. |
| ¿Qué harían distinto? | Simular con estratos y conglomerados, que aumentaría las varianzas y el tamaño de cruce con Dw. |

---

## Recomendaciones para el ensayo
- Hagan un ensayo completo con cronómetro. Si se pasan, el Turno 6 es el que más se puede recortar.
- Quien habla debe señalar en la diapositiva lo que menciona: la barra de Bogotá, la línea roja, la fila de Dw.
- Las cifras clave que todos deberían saber: **0,5043** (valor verdadero), **4,3 % frente a 20,3 %** (Bogotá), **−15 %** (sin pesos) y **32.000** (cruce con Dw).
