# =============================================================================
# 05 — Experimento de simulación Monte Carlo (H1)
#
# "Población": la base final 2024 completa (en_poblacion & responde).
# Valor de referencia: T = theil_A sobre toda la base 2024.
# Para cada n ∈ {500, 2.000, 10.000, 50.000} se sacan 500 submuestras por
# muestreo aleatorio simple SIN reemplazo de personas; cada persona conserva su
# factor de expansión (fex_aj). En cada submuestra se calculan A, B, C y D.
#
# Medidas: sesgo, varianza, ECM = sesgo² + varianza y eficiencia relativa
# ER = ECM(A) / ECM(j) (ER < 1: A es mejor que j).
# H1: con n = 50.000, prueba t pareada unilateral sobre las diferencias de
# pérdidas d_j = (A - T)² - (j - T)²;  H0: media(d_j) >= 0  vs  H1: media(d_j) < 0.
#
# Entrada: data/final/geih_2024.csv.gz
# Salida:  outputs/simulacion_*.csv  y  latex/fig_simulacion_*.png
# =============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)

source("scripts/00_funciones.R")   # theil_A, theil_B, theil_C, theil_D, leer_final()


# Parámetros ----

set.seed(2024)                              # semilla fija: mismos resultados en cualquier computador
R         <- 500                            # réplicas por tamaño de muestra
tamanos   <- c(500, 2000, 10000, 50000)
alfa      <- 0.05


# Población y valor de referencia ----

base <- leer_final(2024) %>% filter(en_poblacion, responde)
y <- base$ingreso
w <- base$fex_aj
N <- length(y)

T_ref <- theil_A(y, w)
cat("Población:", N, "personas | T de referencia (A, base 2024 completa) =", round(T_ref, 4), "\n")


# Réplicas ----

replicas <- list()
for (n in tamanos) {
  inicio <- Sys.time()
  for (r in 1:R) {
    i <- sample(N, n)                       # muestreo aleatorio simple sin reemplazo
    replicas[[paste(n, r)]] <- data.frame(
      n = n, replica = r,
      A = theil_A(y[i], w[i]),
      B = theil_B(y[i]),
      C = theil_C(y[i]),
      D = theil_D(y[i])
    )
  }
  cat("n =", n, "listo en", round(difftime(Sys.time(), inicio, units = "secs")), "s\n")
}
replicas <- bind_rows(replicas)

dir.create("outputs", showWarnings = FALSE)
write.csv(replicas, "outputs/simulacion_replicas.csv", row.names = FALSE)


# Sesgo, varianza, ECM y eficiencia relativa ----

resumen <- replicas %>%
  pivot_longer(c(A, B, C, D), names_to = "estimador", values_to = "valor") %>%
  group_by(n, estimador) %>%
  summarise(
    media    = mean(valor),
    sesgo    = mean(valor) - T_ref,
    varianza = mean((valor - mean(valor))^2),    # divisor R, así ECM = sesgo² + varianza
    ecm      = mean((valor - T_ref)^2),
    .groups  = "drop"
  ) %>%
  group_by(n) %>%
  mutate(er = ecm[estimador == "A"] / ecm) %>%   # ER = ECM(A) / ECM(j)
  ungroup() %>%
  mutate(T_ref = T_ref, .before = 1)

write.csv(resumen, "outputs/simulacion_resumen.csv", row.names = FALSE)
print(as.data.frame(resumen %>% mutate(across(where(is.numeric), ~ signif(.x, 4)))))


# H1: prueba t pareada unilateral con n = 50.000 ----

r50 <- replicas %>% filter(n == 50000)
perdida <- function(x) (x - T_ref)^2

h1 <- bind_rows(lapply(c("B", "C", "D"), function(j) {
  prueba <- t.test(perdida(r50$A), perdida(r50[[j]]), paired = TRUE, alternative = "less")
  data.frame(
    competidor = j,
    media_d    = unname(prueba$estimate),     # media de d_j = pérdida(A) - pérdida(j)
    t          = unname(prueba$statistic),
    gl         = unname(prueba$parameter),
    valor_p    = prueba$p.value,
    decision   = ifelse(prueba$p.value < alfa, "Se rechaza H0", "No se rechaza H0")
  )
}))

write.csv(h1, "outputs/simulacion_h1.csv", row.names = FALSE)
print(h1)
cat("Conclusión H1:", ifelse(all(h1$valor_p < alfa),
                             "se rechaza H0 frente a B, C y D: A tiene menor ECM.",
                             "no se rechaza H0 frente a todos los competidores."), "\n")


# Figuras ----

tema <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank(),
        legend.position = "bottom")

g_ecm <- ggplot(resumen, aes(x = n, y = ecm, colour = estimador)) +
  geom_line() + geom_point() +
  scale_x_log10(breaks = tamanos, labels = format(tamanos, big.mark = ".")) +
  scale_y_log10() +
  labs(title = "Error cuadrático medio de cada estimador según el tamaño de muestra",
       subtitle = "500 réplicas por tamaño. Escalas logarítmicas.",
       x = "Tamaño de la submuestra (n)", y = "ECM", colour = "Estimador") +
  tema
ggsave("latex/fig_simulacion_ecm.png", g_ecm, width = 8, height = 5, dpi = 300)

g_dist <- r50 %>%
  pivot_longer(c(A, B, C, D), names_to = "estimador", values_to = "valor") %>%
  ggplot(aes(x = valor)) +
  geom_histogram(bins = 40, fill = "#2c7fb8") +
  geom_vline(xintercept = T_ref, colour = "#e34a33", linetype = "dashed") +
  facet_wrap(~ estimador, scales = "free_x", nrow = 1) +
  labs(title = "Distribución de las 500 estimaciones con n = 50.000",
       subtitle = "Línea roja = valor de referencia (A sobre la base 2024 completa).",
       x = "Theil estimado", y = "Réplicas") +
  tema
ggsave("latex/fig_simulacion_distribucion.png", g_dist, width = 10, height = 4, dpi = 300)

cat("05 listo\n")
