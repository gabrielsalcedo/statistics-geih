# =============================================================================
# 03 — Estadística descriptiva
#
# Lo que pide la guía del curso:
#   1. Medidas de tendencia central, posición, dispersión y forma (cuantitativas)
#   2. Tablas de frecuencias de las cuantitativas agrupadas
#   3. Tablas de frecuencias y diagrama de barras de las cualitativas
#   4. Tablas cruzadas, ingreso por grupo y diagramas de caja
#   5. Histograma del ingreso y ln(ingreso) frente a una normal
#
# Todo está PONDERADO con fex_aj: describe a la población de ocupados, no a los
# encuestados. Personas = en_poblacion & responde (las mismas del Theil).
#
# Entrada: data/final/geih_<año>.csv.gz
# Salida:  outputs/desc_*.csv  y  latex/fig_*.png
# =============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
# El boxplot ponderado usa el paquete quantreg por dentro (debe estar instalado)

source("scripts/00_funciones.R")   # leer_final()


# Parámetros ----

anio_ref  <- 2026     # año principal
anio_base <- 2018     # año de comparación

# Salario mínimo mensual (SMMLV, decretos del Gobierno) para agrupar el ingreso.
# El ingreso de la GEIH es del "mes pasado": quien responde en enero reporta
# diciembre del año anterior, por eso enero usa el SMMLV del año anterior.
smmlv <- c("2017" =  737717, "2018" =  781242, "2019" =  828116, "2020" =  877803,
           "2021" =  908526, "2022" = 1000000, "2023" = 1160000, "2024" = 1300000,
           "2025" = 1423500, "2026" = 1750905)

dir.create("outputs", showWarnings = FALSE)
dir.create("latex",   showWarnings = FALSE)


# =============================================================================
# FUNCIONES PONDERADAS (con w = 1 son las fórmulas de clase)
# =============================================================================

w_media <- function(x, w) sum(w * x) / sum(w)
w_var   <- function(x, w) sum(w * (x - w_media(x, w))^2) / sum(w)
w_sd    <- function(x, w) sqrt(w_var(x, w))

# Cuantil ponderado: el primer valor donde el peso acumulado alcanza p
w_cuantil <- function(x, w, p) {
  o  <- order(x)
  cw <- cumsum(w[o]) / sum(w)
  sapply(p, function(pp) x[o][which(cw >= pp)[1]])
}

# Moda ponderada: el valor exacto con más peso
w_moda <- function(x, w) {
  t <- tapply(w, x, sum)
  as.numeric(names(t)[which.max(t)])
}

# Asimetría (0 = simétrica) y curtosis en exceso (0 = como la normal)
w_asimetria <- function(x, w) (sum(w * (x - w_media(x, w))^3) / sum(w)) / w_sd(x, w)^3
w_curtosis  <- function(x, w) (sum(w * (x - w_media(x, w))^4) / sum(w)) / w_sd(x, w)^4 - 3

resumen_cuanti <- function(x, w) {
  q <- w_cuantil(x, w, c(0.10, 0.25, 0.50, 0.75, 0.90))
  data.frame(
    media = w_media(x, w), mediana = q[3], moda = w_moda(x, w),
    minimo = min(x), p10 = q[1], q1 = q[2], q3 = q[4], p90 = q[5], maximo = max(x),
    rango = max(x) - min(x), ric = q[4] - q[2], desv_est = w_sd(x, w),
    cv_pct = 100 * w_sd(x, w) / w_media(x, w),
    asimetria = w_asimetria(x, w), curtosis = w_curtosis(x, w)
  )
}

# Frecuencias: absoluta (muestra), población (promedio mensual), relativa y acumulada
tabla_frecuencias <- function(d, var) {
  n_meses <- n_distinct(d$MES)
  d %>%
    filter(!is.na(.data[[var]])) %>%
    group_by(categoria = .data[[var]]) %>%
    summarise(n_muestra = n(), poblacion = sum(w) / n_meses, .groups = "drop") %>%
    mutate(pct_muestra   = 100 * n_muestra / sum(n_muestra),
           pct_poblacion = 100 * poblacion / sum(poblacion),
           pct_acumulado = cumsum(pct_poblacion),
           categoria     = as.character(categoria),
           variable      = var, .before = 1)
}

tema <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

etiquetas_dim <- c(educ = "Educación", formal = "Formalidad", sexo = "Sexo",
                   region = "Región", estrato = "Estrato", posicion = "Posición ocupacional")


# =============================================================================
# CARGA
# =============================================================================

cargar <- function(anio) {
  leer_final(anio) %>%
    filter(en_poblacion, responde) %>%
    mutate(w             = fex_aj,
           smmlv_ref     = if_else(MES == 1, smmlv[as.character(anio - 1)], smmlv[as.character(anio)]),
           ingreso_smmlv = ingreso / smmlv_ref,
           ln_ingreso    = log(ingreso))
}

d_ref  <- cargar(anio_ref)
d_base <- cargar(anio_base)


# =============================================================================
# 1. MEDIDAS DE LAS VARIABLES CUANTITATIVAS
# =============================================================================

medidas <- bind_rows(lapply(list(d_base, d_ref), function(d) {
  h <- !is.na(d$horas)
  bind_rows(
    data.frame(anio = d$ANIO[1], variable = "Ingreso (pesos)", resumen_cuanti(d$ingreso,    d$w)),
    data.frame(anio = d$ANIO[1], variable = "ln(ingreso)",     resumen_cuanti(d$ln_ingreso, d$w)),
    data.frame(anio = d$ANIO[1], variable = "Edad (años)",     resumen_cuanti(d$edad,       d$w)),
    data.frame(anio = d$ANIO[1], variable = "Horas semanales", resumen_cuanti(d$horas[h],   d$w[h]))
  )
})) %>%
  mutate(across(where(is.numeric) & !anio, ~ round(.x, 3)))

write.csv(medidas, "outputs/desc_medidas_cuantitativas.csv", row.names = FALSE)


# =============================================================================
# 2. FRECUENCIAS DE LAS CUANTITATIVAS AGRUPADAS
# =============================================================================
# El ingreso se agrupa en salarios mínimos: con una distribución tan asimétrica,
# clases de igual ancho (regla de Sturges) dejarían casi a todos en la primera.

agrupar <- function(d) {
  d %>% mutate(
    clase_ingreso = cut(ingreso_smmlv, breaks = c(0, 0.5, 0.95, 1.05, 2, 4, 8, Inf), right = FALSE,
                        labels = c("< 0,5", "0,5 a 0,95", "0,95 a 1,05 (≈ 1 SMMLV)", "1,05 a 2", "2 a 4", "4 a 8", "8 o más")),
    clase_edad  = cut(edad, breaks = c(15, 25, 35, 45, 55, 65, Inf), right = FALSE,
                      labels = c("15-24", "25-34", "35-44", "45-54", "55-64", "65 o más")),
    clase_horas = cut(horas, breaks = c(0, 20, 40, 49, 61, Inf), right = FALSE,
                      labels = c("< 20", "20-39", "40-48", "49-60", "más de 60"))
  )
}

d_ref  <- agrupar(d_ref)
d_base <- agrupar(d_base)

freq_cuanti <- bind_rows(lapply(list(d_base, d_ref), function(d) {
  bind_rows(lapply(c("clase_ingreso", "clase_edad", "clase_horas"), function(v) {
    tabla_frecuencias(d, v) %>% mutate(anio = d$ANIO[1], .before = 1)
  }))
})) %>%
  mutate(across(starts_with("pct"), ~ round(.x, 2)), poblacion = round(poblacion))

write.csv(freq_cuanti, "outputs/desc_frecuencias_cuantitativas.csv", row.names = FALSE)


# =============================================================================
# 3. FRECUENCIAS DE LAS CUALITATIVAS Y DIAGRAMA DE BARRAS
# =============================================================================
# pct_muestra frente a pct_poblacion: la diferencia muestra por qué hay que ponderar.

freq_cuali <- bind_rows(lapply(c("sexo", "educ", "formal", "region", "estrato", "posicion"),
                               function(v) tabla_frecuencias(d_ref, v))) %>%
  mutate(across(starts_with("pct"), ~ round(.x, 2)), poblacion = round(poblacion))

write.csv(freq_cuali, "outputs/desc_frecuencias_cualitativas.csv", row.names = FALSE)

g_barras <- freq_cuali %>%
  filter(variable != "posicion") %>%
  mutate(variable = etiquetas_dim[variable], categoria = factor(categoria, levels = unique(categoria))) %>%
  ggplot(aes(x = categoria, y = pct_poblacion / 100)) +
  geom_col(fill = "#2c7fb8") +
  geom_text(aes(label = percent(pct_poblacion / 100, accuracy = 0.1)), vjust = -0.3, size = 2.8) +
  facet_wrap(~ variable, scales = "free_x", ncol = 3) +
  scale_y_continuous(labels = percent, expand = expansion(mult = c(0, 0.15))) +
  labs(title = paste0("Composición de los ocupados, ", anio_ref), x = NULL,
       y = "Porcentaje de ocupados (ponderado)") +
  tema + theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("latex/fig_barras_cualitativas.png", g_barras, width = 10, height = 6, dpi = 300)


# =============================================================================
# 4. BIVARIADAS: TABLAS CRUZADAS, INGRESO POR GRUPO Y DIAGRAMAS DE CAJA
# =============================================================================

# Tablas cruzadas: porcentaje por fila, ponderado
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

write.csv(tabla_cruzada(d_ref, "educ",    "formal"), "outputs/desc_cruzada_educ_formal.csv",    row.names = FALSE)
write.csv(tabla_cruzada(d_ref, "sexo",    "formal"), "outputs/desc_cruzada_sexo_formal.csv",    row.names = FALSE)
write.csv(tabla_cruzada(d_ref, "region",  "formal"), "outputs/desc_cruzada_region_formal.csv",  row.names = FALSE)
write.csv(tabla_cruzada(d_ref, "estrato", "educ"),   "outputs/desc_cruzada_estrato_educ.csv",   row.names = FALSE)

# Ingreso por grupo: la intuición del componente "entre".
# p_k = % de la población; s_k = % del ingreso; razón = media del grupo / media total.
dims <- c("educ", "formal", "sexo", "region", "estrato")
mu   <- w_media(d_ref$ingreso, d_ref$w)

ingreso_grupo <- bind_rows(lapply(dims, function(v) {
  d_ref %>%
    group_by(grupo = .data[[v]]) %>%
    summarise(pct_poblacion = 100 * sum(w) / sum(d_ref$w),
              pct_ingreso   = 100 * sum(w * ingreso) / sum(d_ref$w * d_ref$ingreso),
              media_smmlv   = w_media(ingreso_smmlv, w),
              mediana_smmlv = w_cuantil(ingreso_smmlv, w, 0.5),
              cv_pct        = 100 * w_sd(ingreso, w) / w_media(ingreso, w),
              razon_media   = w_media(ingreso, w) / mu,
              .groups = "drop") %>%
    mutate(grupo = as.character(grupo), dimension = etiquetas_dim[v], .before = 1)
})) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

write.csv(ingreso_grupo, "outputs/desc_ingreso_por_grupo.csv", row.names = FALSE)

# Diagramas de caja del ingreso por dimensión (ponderados, escala logarítmica)
g_cajas <- bind_rows(lapply(dims, function(v) {
  d_ref %>% transmute(dimension = etiquetas_dim[v], grupo = as.character(.data[[v]]), ingreso_smmlv, w)
})) %>%
  mutate(grupo = factor(grupo, levels = unique(unlist(lapply(dims, function(v) levels(d_ref[[v]])))))) %>%
  ggplot(aes(x = grupo, y = ingreso_smmlv, weight = w)) +
  geom_boxplot(outlier.shape = NA, fill = "#a6bddb") +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "#e34a33") +
  facet_wrap(~ dimension, scales = "free_x", ncol = 3) +
  scale_y_log10(breaks = c(0.25, 0.5, 1, 2, 4, 8, 16), labels = label_number(accuracy = 0.01)) +
  coord_cartesian(ylim = c(0.1, 20)) +
  labs(title = paste0("Ingreso laboral por grupo, ", anio_ref),
       subtitle = "Escala logarítmica. Línea roja = 1 salario mínimo. Sin valores atípicos en el gráfico.",
       x = NULL, y = "Ingreso laboral (salarios mínimos)") +
  tema + theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("latex/fig_boxplot_ingreso_grupo.png", g_cajas, width = 10, height = 7, dpi = 300)


# =============================================================================
# 5. HISTOGRAMA DEL INGRESO Y ln(INGRESO) FRENTE A UNA NORMAL
# =============================================================================

g_hist <- d_ref %>%
  filter(ingreso_smmlv <= 6) %>%
  ggplot(aes(x = ingreso_smmlv, weight = w)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 0.1, boundary = 0, fill = "#2c7fb8") +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "#e34a33") +
  labs(title = paste0("Distribución del ingreso laboral, ", anio_ref),
       subtitle = paste0("Línea roja = 1 salario mínimo. Se muestran los ingresos hasta 6 SMMLV (",
                         percent(sum(d_ref$w[d_ref$ingreso_smmlv <= 6]) / sum(d_ref$w), accuracy = 0.1),
                         " de los ocupados)."),
       x = "Ingreso laboral (salarios mínimos)", y = "Densidad (ponderada)") +
  tema

ggsave("latex/fig_histograma_ingreso.png", g_hist, width = 8, height = 5, dpi = 300)

# Si el ingreso fuera lognormal (supuesto de C y D), el histograma seguiría la curva roja
m_ln <- w_media(d_ref$ln_ingreso, d_ref$w)
s_ln <- w_sd(d_ref$ln_ingreso, d_ref$w)

g_ln <- ggplot(d_ref, aes(x = ln_ingreso, weight = w)) +
  geom_histogram(aes(y = after_stat(density)), bins = 80, fill = "#a6bddb") +
  stat_function(fun = dnorm, args = list(mean = m_ln, sd = s_ln), colour = "#e34a33",
                linewidth = 0.9, inherit.aes = FALSE) +
  labs(title = paste0("ln(ingreso) frente a una distribución normal, ", anio_ref),
       subtitle = paste0("Curva roja: normal con la misma media y desviación. Asimetría = ",
                         round(w_asimetria(d_ref$ln_ingreso, d_ref$w), 2), ", curtosis en exceso = ",
                         round(w_curtosis(d_ref$ln_ingreso, d_ref$w), 2), "."),
       x = "ln(ingreso laboral)", y = "Densidad (ponderada)") +
  tema

ggsave("latex/fig_ln_ingreso_normal.png", g_ln, width = 8, height = 5, dpi = 300)

cat("03 listo: tablas en outputs/ y figuras en latex/\n")
