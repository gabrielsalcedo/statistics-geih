# =============================================================================
# ETAPA 4 — Estadística descriptiva
#
# Cubre lo que pide la guía del proyecto (corte 2) y, a la vez, muestra los
# hechos que justifican el proyecto:
#   1. Medidas de tendencia central, posición, dispersión y forma (cuantitativas)
#   2. Tablas de frecuencias agrupadas (cuantitativas)
#   3. Tablas de frecuencias y diagramas de barras (cualitativas)
#   4. Tablas cruzadas y gráficas bivariadas
#   5. Correlación y recta de regresión (cuantitativa vs. cuantitativa)
#   6. Evolución 2018–2026
#   7. Gráficas que justifican el proyecto
#
# Todas las estadísticas son PONDERADAS con fex_aj: describen a la población
# de ocupados, no a los encuestados. Población = en_poblacion & responde,
# la misma sobre la que se calcula el Theil.
#
# Entrada: data/processed/geih_<año>.csv.gz  (versionada en GitHub)
# Salida:  outputs/descriptiva/tablas/*.csv  y  outputs/descriptiva/figuras/*.png
# El boxplot ponderado necesita el paquete quantreg instalado.
# =============================================================================


# Librerías ----

library(here)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

source(here("R", "config.R"))   # anios_theil, anio_ref, anio_base, smmlv, semilla
source(here("R", "datos.R"))    # cargar_analitica()


# Parámetros ----
# anio_ref (año principal) y anio_base (año de comparación) vienen de R/config.R.

anios_serie <- anios_theil                # sin 2020

ruta_tab <- here("outputs", "descriptiva", "tablas")
ruta_fig <- here("outputs", "descriptiva", "figuras")
dir.create(ruta_tab, showWarnings = FALSE, recursive = TRUE)
dir.create(ruta_fig, showWarnings = FALSE, recursive = TRUE)


# Salario mínimo (SMMLV) ----
# La tabla smmlv está en R/config.R. Sirve para expresar el ingreso en
# salarios mínimos: así los años son comparables sin deflactar y el valor
# tiene lectura económica directa.
# El ingreso de la GEIH es "el mes pasado": quien fue encuestado en enero
# reporta diciembre del año anterior, por eso enero usa el SMMLV del año anterior.


# =============================================================================
# FUNCIONES PONDERADAS
# =============================================================================
# Todas reciben x (valores) y w (pesos). Con w = 1 son las fórmulas de clase.

w_media <- function(x, w) sum(w * x) / sum(w)

w_var <- function(x, w) {
  m <- w_media(x, w)
  sum(w * (x - m)^2) / sum(w)
}

w_sd <- function(x, w) sqrt(w_var(x, w))

# Cuantil ponderado: el primer valor donde el peso acumulado alcanza p
w_cuantil <- function(x, w, p) {
  o  <- order(x)
  x  <- x[o]
  cw <- cumsum(w[o]) / sum(w)
  sapply(p, function(pp) x[which(cw >= pp)[1]])
}

# Moda ponderada: el valor exacto con más peso (útil en edad, horas e ingreso,
# que se reporta en cifras redondas)
w_moda <- function(x, w) {
  t <- tapply(w, x, sum)
  as.numeric(names(t)[which.max(t)])
}

# Coeficiente de asimetría (0 = simétrica; > 0 = cola larga a la derecha)
w_asimetria <- function(x, w) {
  m <- w_media(x, w)
  (sum(w * (x - m)^3) / sum(w)) / w_sd(x, w)^3
}

# Curtosis en exceso (0 = como la normal; > 0 = colas más pesadas)
w_curtosis <- function(x, w) {
  m <- w_media(x, w)
  (sum(w * (x - m)^4) / sum(w)) / w_sd(x, w)^4 - 3
}

# Correlación de Pearson ponderada
w_cor <- function(x, y, w) {
  mx <- w_media(x, w)
  my <- w_media(y, w)
  cov <- sum(w * (x - mx) * (y - my)) / sum(w)
  cov / (w_sd(x, w) * w_sd(y, w))
}

# Tabla de medidas para una variable cuantitativa
resumen_cuanti <- function(x, w) {
  q <- w_cuantil(x, w, c(0.10, 0.25, 0.50, 0.75, 0.90))
  data.frame(
    media      = w_media(x, w),
    mediana    = q[3],
    moda       = w_moda(x, w),
    minimo     = min(x),
    p10        = q[1],
    q1         = q[2],
    q3         = q[4],
    p90        = q[5],
    maximo     = max(x),
    rango      = max(x) - min(x),
    ric        = q[4] - q[2],
    desv_est   = w_sd(x, w),
    cv_pct     = 100 * w_sd(x, w) / w_media(x, w),
    asimetria  = w_asimetria(x, w),
    curtosis   = w_curtosis(x, w)
  )
}

# Tabla de frecuencias (absoluta, relativa y acumulada), muestra y población
tabla_frecuencias <- function(d, var) {
  n_meses <- n_distinct(d$MES)
  d %>%
    filter(!is.na(.data[[var]])) %>%
    group_by(categoria = .data[[var]]) %>%
    summarise(
      n_muestra = n(),
      poblacion = sum(w) / n_meses,          # promedio mensual de ocupados
      .groups   = "drop"
    ) %>%
    mutate(
      pct_muestra    = 100 * n_muestra / sum(n_muestra),
      pct_poblacion  = 100 * poblacion / sum(poblacion),
      pct_acumulado  = cumsum(pct_poblacion),
      categoria      = as.character(categoria),   # texto, para poder unir tablas de distintas variables
      variable       = var,
      .before        = 1
    )
}

guardar_tabla <- function(t, nombre) {
  write.csv(t, file.path(ruta_tab, paste0(nombre, ".csv")), row.names = FALSE)
  t
}

guardar_figura <- function(g, nombre, ancho = 8, alto = 5) {
  ggsave(file.path(ruta_fig, paste0(nombre, ".png")), g, width = ancho, height = alto, dpi = 300)
  g
}

tema <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())


# =============================================================================
# CARGA
# =============================================================================

etiquetas_dim <- c(
  educ = "Educación", formal = "Formalidad", sexo = "Sexo",
  region = "Región", estrato = "Estrato", posicion = "Posición ocupacional"
)

cargar <- function(anio) {
  cargar_analitica(anio) %>%
    filter(en_poblacion, responde) %>%
    mutate(
      w             = fex_aj,
      smmlv_ref     = if_else(MES == 1, smmlv[as.character(anio - 1)], smmlv[as.character(anio)]),
      ingreso_smmlv = ingreso / smmlv_ref,
      ln_ingreso    = log(ingreso)
    )
}

d_ref  <- cargar(anio_ref)
d_base <- cargar(anio_base)


# =============================================================================
# 1. MEDIDAS DE LAS VARIABLES CUANTITATIVAS
# =============================================================================

medidas <- bind_rows(lapply(list(d_base, d_ref), function(d) {
  bind_rows(
    data.frame(anio = d$ANIO[1], variable = "Ingreso (pesos)",          resumen_cuanti(d$ingreso,       d$w)),
    data.frame(anio = d$ANIO[1], variable = "Ingreso (SMMLV)",          resumen_cuanti(d$ingreso_smmlv, d$w)),
    data.frame(anio = d$ANIO[1], variable = "ln(ingreso)",              resumen_cuanti(d$ln_ingreso,    d$w)),
    data.frame(anio = d$ANIO[1], variable = "Edad (años)",              resumen_cuanti(d$edad,          d$w)),
    data.frame(anio = d$ANIO[1], variable = "Horas semanales",          resumen_cuanti(d$horas[!is.na(d$horas)], d$w[!is.na(d$horas)]))
  )
})) %>%
  mutate(across(where(is.numeric) & !anio, ~ round(.x, 3))) %>%
  guardar_tabla("01_medidas_cuantitativas")

cat("\n1. Medidas de las variables cuantitativas:\n")
print(medidas, row.names = FALSE)


# =============================================================================
# 2. FRECUENCIAS AGRUPADAS DE LAS CUANTITATIVAS
# =============================================================================
# El ingreso se agrupa en salarios mínimos, no con la regla de Sturges:
# con una distribución tan asimétrica, clases de igual ancho dejarían casi
# toda la población en la primera clase.

agrupar <- function(d) {
  d %>%
    mutate(
      clase_ingreso = cut(
        ingreso_smmlv,
        breaks = c(0, 0.5, 0.95, 1.05, 2, 4, 8, Inf),
        labels = c("< 0,5", "0,5 a 0,95", "0,95 a 1,05 (≈ 1 SMMLV)", "1,05 a 2", "2 a 4", "4 a 8", "8 o más"),
        right  = FALSE
      ),
      clase_edad = cut(
        edad, breaks = c(15, 25, 35, 45, 55, 65, Inf),
        labels = c("15-24", "25-34", "35-44", "45-54", "55-64", "65 o más"), right = FALSE
      ),
      clase_horas = cut(
        horas, breaks = c(0, 20, 40, 49, 61, Inf),
        labels = c("< 20", "20-39", "40-48", "49-60", "más de 60"), right = FALSE
      )
    )
}

d_ref  <- agrupar(d_ref)
d_base <- agrupar(d_base)

freq_cuanti <- bind_rows(lapply(list(d_base, d_ref), function(d) {
  bind_rows(lapply(c("clase_ingreso", "clase_edad", "clase_horas"), function(v) {
    tabla_frecuencias(d, v) %>% mutate(anio = d$ANIO[1], .before = 1)
  }))
})) %>%
  mutate(categoria = as.character(categoria), across(starts_with("pct"), ~ round(.x, 2)), poblacion = round(poblacion)) %>%
  guardar_tabla("02_frecuencias_cuantitativas_agrupadas")

cat("\n2. Ingreso agrupado en salarios mínimos:\n")
print(freq_cuanti %>% filter(variable == "clase_ingreso") %>% select(anio, categoria, pct_poblacion, pct_acumulado), row.names = FALSE)


# =============================================================================
# 3. FRECUENCIAS DE LAS CUALITATIVAS
# =============================================================================
# pct_muestra frente a pct_poblacion: la diferencia muestra por qué hay que
# ponderar (es la intuición del estimador A frente al B).

vars_cuali <- c("sexo", "educ", "formal", "region", "estrato", "posicion")

freq_cuali <- bind_rows(lapply(vars_cuali, function(v) tabla_frecuencias(d_ref, v))) %>%
  mutate(categoria = as.character(categoria), across(starts_with("pct"), ~ round(.x, 2)), poblacion = round(poblacion)) %>%
  guardar_tabla("03_frecuencias_cualitativas")

cat("\n3. Frecuencias de las variables cualitativas (", anio_ref, "):\n", sep = "")
print(freq_cuali %>% select(variable, categoria, n_muestra, pct_muestra, pct_poblacion), row.names = FALSE)

g_barras <- freq_cuali %>%
  filter(variable != "posicion") %>%
  mutate(
    variable  = etiquetas_dim[variable],
    categoria = factor(categoria, levels = unique(categoria))
  ) %>%
  ggplot(aes(x = categoria, y = pct_poblacion / 100)) +
  geom_col(fill = "#2c7fb8") +
  geom_text(aes(label = percent(pct_poblacion / 100, accuracy = 0.1)), vjust = -0.3, size = 2.8) +
  facet_wrap(~ variable, scales = "free_x", ncol = 3) +
  scale_y_continuous(labels = percent, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = paste0("Composición de los ocupados, ", anio_ref),
    x = NULL, y = "Porcentaje de ocupados (ponderado)"
  ) +
  tema +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

guardar_figura(g_barras, "03_barras_cualitativas", ancho = 10, alto = 6)


# =============================================================================
# 4. BIVARIADAS: TABLAS CRUZADAS E INGRESO POR GRUPO
# =============================================================================

# Tablas cruzadas (porcentaje por fila, ponderado) ----

tabla_cruzada <- function(d, fila, columna) {
  t <- d %>%
    filter(!is.na(.data[[fila]]), !is.na(.data[[columna]])) %>%
    group_by(f = .data[[fila]], k = .data[[columna]]) %>%
    summarise(w = sum(w), .groups = "drop") %>%
    group_by(f) %>%
    mutate(pct_fila = round(100 * w / sum(w), 1)) %>%
    ungroup() %>%
    select(-w) %>%
    pivot_wider(names_from = k, values_from = pct_fila)
  names(t)[1] <- fila
  t
}

cruzadas <- list(
  educ_formal     = tabla_cruzada(d_ref, "educ",     "formal"),
  sexo_formal     = tabla_cruzada(d_ref, "sexo",     "formal"),
  region_formal   = tabla_cruzada(d_ref, "region",   "formal"),
  estrato_educ    = tabla_cruzada(d_ref, "estrato",  "educ")
)

for (n in names(cruzadas)) {
  guardar_tabla(cruzadas[[n]], paste0("04_cruzada_", n))
  cat("\n4. Tabla cruzada", n, "(% por fila):\n")
  print(as.data.frame(cruzadas[[n]]), row.names = FALSE)
}


# Ingreso por grupo: la intuición del componente between ----
# p_k = % de la población; s_k = % del ingreso total; razón = media del grupo / media total.
# Un grupo con s_k mucho mayor que p_k gana por encima del promedio.

dims <- c("educ", "formal", "sexo", "region", "estrato")

ingreso_grupo <- bind_rows(lapply(dims, function(v) {
  mu <- w_media(d_ref$ingreso, d_ref$w)
  d_ref %>%
    group_by(grupo = .data[[v]]) %>%            # agrupa por el factor: conserva el orden de las categorías
    summarise(
      pct_poblacion   = 100 * sum(w) / sum(d_ref$w),
      pct_ingreso     = 100 * sum(w * ingreso) / sum(d_ref$w * d_ref$ingreso),
      media_smmlv     = w_media(ingreso_smmlv, w),
      mediana_smmlv   = w_cuantil(ingreso_smmlv, w, 0.5),
      cv_pct          = 100 * w_sd(ingreso, w) / w_media(ingreso, w),
      razon_media     = w_media(ingreso, w) / mu,
      .groups = "drop"
    ) %>%
    mutate(grupo = as.character(grupo), dimension = etiquetas_dim[v], .before = 1)
})) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2))) %>%
  guardar_tabla("04_ingreso_por_grupo")

cat("\n4. Ingreso por grupo (", anio_ref, "):\n", sep = "")
print(ingreso_grupo, row.names = FALSE)


# Diagramas de caja del ingreso por dimensión ----

g_cajas <- bind_rows(lapply(dims, function(v) {
  d_ref %>%
    transmute(dimension = etiquetas_dim[v], grupo = as.character(.data[[v]]), ingreso_smmlv, w)
})) %>%
  mutate(grupo = factor(grupo, levels = unique(unlist(lapply(dims, function(v) levels(d_ref[[v]])))))) %>%
  ggplot(aes(x = grupo, y = ingreso_smmlv, weight = w)) +
  geom_boxplot(outlier.shape = NA, fill = "#a6bddb") +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "#e34a33") +
  facet_wrap(~ dimension, scales = "free_x", ncol = 3) +
  scale_y_log10(breaks = c(0.25, 0.5, 1, 2, 4, 8, 16), labels = label_number(accuracy = 0.01)) +
  coord_cartesian(ylim = c(0.1, 20)) +
  labs(
    title    = paste0("Ingreso laboral por grupo, ", anio_ref),
    subtitle = "Escala logarítmica. Línea roja = 1 salario mínimo. Sin valores atípicos en el gráfico.",
    x = NULL, y = "Ingreso laboral (salarios mínimos)"
  ) +
  tema +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

guardar_figura(g_cajas, "04_cajas_ingreso_por_grupo", ancho = 10, alto = 7)


# =============================================================================
# 5. CORRELACIÓN Y REGRESIÓN (CUANTITATIVAS)
# =============================================================================

correlaciones <- data.frame(
  par = c("ingreso - edad", "ln(ingreso) - edad", "ingreso - horas", "ln(ingreso) - horas", "edad - horas"),
  r   = with(d_ref[!is.na(d_ref$horas), ], c(
    w_cor(ingreso,    edad,  w),
    w_cor(ln_ingreso, edad,  w),
    w_cor(ingreso,    horas, w),
    w_cor(ln_ingreso, horas, w),
    w_cor(edad,       horas, w)
  ))
) %>%
  mutate(r = round(r, 3)) %>%
  guardar_tabla("05_correlaciones")

cat("\n5. Correlaciones de Pearson ponderadas (", anio_ref, "):\n", sep = "")
print(correlaciones, row.names = FALSE)

# Dispersión: una submuestra de 4.000 personas seleccionada según su peso,
# para que el gráfico represente a la población y sea legible.
set.seed(semilla_descriptiva)
muestra_graf <- d_ref %>% filter(!is.na(horas)) %>% slice_sample(n = 4000, weight_by = w)

g_disp <- ggplot(muestra_graf, aes(x = horas, y = ln_ingreso)) +
  geom_jitter(alpha = 0.15, width = 0.4, height = 0, size = 0.8) +
  geom_smooth(method = "lm", se = FALSE, colour = "#e34a33") +
  labs(
    title    = paste0("Horas trabajadas e ingreso, ", anio_ref),
    subtitle = paste0("r ponderado = ", correlaciones$r[4], ". Submuestra de 4.000 ocupados seleccionada según el factor de expansión."),
    x = "Horas semanales", y = "ln(ingreso laboral)"
  ) +
  tema

guardar_figura(g_disp, "05_dispersion_horas_ingreso")


# =============================================================================
# 6. EVOLUCIÓN 2018–2026
# =============================================================================
# Todo en salarios mínimos o en porcentajes, para comparar años sin deflactar.

evolucion <- bind_rows(lapply(anios_serie, function(a) {
  d <- cargar(a)
  data.frame(
    anio                = a,
    # Población de estudio (no el total de ocupados), promedio mensual
    poblacion_estudio_millones = sum(d$w) / n_distinct(d$MES) / 1e6,
    media_smmlv         = w_media(d$ingreso_smmlv, d$w),
    mediana_smmlv       = w_cuantil(d$ingreso_smmlv, d$w, 0.5),
    pct_cerca_1_smmlv   = 100 * sum(d$w[d$ingreso_smmlv >= 0.95 & d$ingreso_smmlv < 1.05]) / sum(d$w),
    pct_bajo_1_smmlv    = 100 * sum(d$w[d$ingreso_smmlv < 0.95]) / sum(d$w),
    cv_ingreso_pct      = 100 * w_sd(d$ingreso, d$w) / w_media(d$ingreso, d$w),
    pct_formal          = 100 * sum(d$w[d$formal == "Formal"]) / sum(d$w),
    pct_superior        = 100 * sum(d$w[d$educ == "Superior"]) / sum(d$w),
    pct_mujeres         = 100 * sum(d$w[d$sexo == "Mujer"]) / sum(d$w)
  )
})) %>%
  mutate(across(-anio, ~ round(.x, 2))) %>%
  guardar_tabla("06_evolucion")

cat("\n6. Evolución 2018–2026:\n")
print(evolucion, row.names = FALSE)


# =============================================================================
# 7. GRÁFICAS QUE JUSTIFICAN EL PROYECTO
# =============================================================================

# 7a. Distribución del ingreso: el pico en el salario mínimo ----

g_hist <- d_ref %>%
  filter(ingreso_smmlv <= 6) %>%
  ggplot(aes(x = ingreso_smmlv, weight = w)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 0.1, boundary = 0, fill = "#2c7fb8") +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "#e34a33") +
  labs(
    title    = paste0("Distribución del ingreso laboral, ", anio_ref),
    subtitle = paste0("Línea roja = 1 salario mínimo. Se muestran los ingresos hasta 6 SMMLV (",
                      percent(sum(d_ref$w[d_ref$ingreso_smmlv <= 6]) / sum(d_ref$w), accuracy = 0.1),
                      " de los ocupados)."),
    x = "Ingreso laboral (salarios mínimos)", y = "Densidad (ponderada)"
  ) +
  tema

guardar_figura(g_hist, "07a_histograma_ingreso")


# 7b. ¿Es lognormal el ingreso? ln(ingreso) contra una normal ----
# Si el ingreso fuera lognormal, el histograma seguiría la curva roja.
# Esta gráfica anticipa por qué los estimadores C y D deberían fallar.

m_ln <- w_media(d_ref$ln_ingreso, d_ref$w)
s_ln <- w_sd(d_ref$ln_ingreso, d_ref$w)

g_ln <- ggplot(d_ref, aes(x = ln_ingreso, weight = w)) +
  geom_histogram(aes(y = after_stat(density)), bins = 80, fill = "#a6bddb") +
  # inherit.aes = FALSE: la curva no usa los pesos (sin esto ggplot avisa que los descarta)
  stat_function(fun = dnorm, args = list(mean = m_ln, sd = s_ln), colour = "#e34a33", linewidth = 0.9,
                inherit.aes = FALSE) +
  labs(
    title    = paste0("ln(ingreso) frente a una distribución normal, ", anio_ref),
    subtitle = paste0("Curva roja: normal con la misma media y desviación. Asimetría = ",
                      round(w_asimetria(d_ref$ln_ingreso, d_ref$w), 2), ", curtosis en exceso = ",
                      round(w_curtosis(d_ref$ln_ingreso, d_ref$w), 2), "."),
    x = "ln(ingreso laboral)", y = "Densidad (ponderada)"
  ) +
  tema

guardar_figura(g_ln, "07b_ln_ingreso_vs_normal")


# 7c. Muestra frente a población: por qué hay que ponderar ----

g_pond <- freq_cuali %>%
  filter(variable %in% c("region", "educ", "formal")) %>%
  select(variable, categoria, Muestra = pct_muestra, `Población (ponderada)` = pct_poblacion) %>%
  pivot_longer(c(Muestra, `Población (ponderada)`), names_to = "base", values_to = "pct") %>%
  mutate(variable = etiquetas_dim[variable], categoria = factor(categoria, levels = unique(categoria))) %>%
  ggplot(aes(x = categoria, y = pct / 100, fill = base)) +
  geom_col(position = "dodge") +
  facet_wrap(~ variable, scales = "free_x") +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = c("#bdbdbd", "#2c7fb8")) +
  labs(
    title    = paste0("La muestra no se parece a la población, ", anio_ref),
    subtitle = "Diferencia entre el porcentaje de encuestados y el porcentaje ponderado con el factor de expansión.",
    x = NULL, y = "Porcentaje", fill = NULL
  ) +
  tema +
  theme(axis.text.x = element_text(angle = 30, hjust = 1), legend.position = "top")

guardar_figura(g_pond, "07c_muestra_vs_poblacion", ancho = 10, alto = 5)


cat("\nListo. Tablas en", ruta_tab, "y figuras en", ruta_fig, "\n")