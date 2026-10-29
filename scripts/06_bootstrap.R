# =============================================================================
# 06 — Bootstrap: intervalos de confianza, H2 y H3
#
# En cada réplica se remuestrean personas CON reemplazo (el mismo número que
# hay en la base) y cada persona conserva su factor de expansión (fex_aj).
#
#   - IC del 95 % del Theil A de cada año: percentiles 2,5 y 97,5.
#   - H2 (2026): S_edu > S_k para toda otra dimensión k.
#       Se rechaza H0 si el percentil 5 de S*_edu - S*_k es > 0 para todas las k.
#   - H3: T_2026 < T_2018.
#       Se rechaza H0 si el percentil 95 de T*_2026 - T*_2018 es < 0.
#
# Entrada: data/final/geih_<año>.csv.gz
# Salida:  outputs/bootstrap_*.csv  y  latex/fig_bootstrap_ic.png
# =============================================================================

library(dplyr)
library(ggplot2)

source("scripts/00_funciones.R")   # theil_A(), theil_decomp(), leer_final()


# Parámetros ----

set.seed(2026)                              # semilla fija
B           <- 500                          # réplicas bootstrap
anios_theil <- c(2018, 2019, 2021:2026)     # sin 2020
dimensiones <- c("educ", "formal", "sexo", "region", "estrato")


# Réplicas del Theil de cada año (y de S por dimensión en 2026) ----

T_boot <- list()
S_boot <- list()

for (anio in anios_theil) {

  inicio <- Sys.time()
  b <- leer_final(anio) %>% filter(en_poblacion, responde)
  y <- b$ingreso
  w <- b$fex_aj
  N <- nrow(b)

  for (r in 1:B) {
    i <- sample(N, N, replace = TRUE)       # remuestreo de personas con reemplazo
    T_boot[[paste(anio, r)]] <- data.frame(anio = anio, replica = r, T = theil_A(y[i], w[i]))

    # H2: porcentaje explicado (S = entre / total) por cada dimensión, en 2026
    if (anio == 2026) {
      S_boot[[r]] <- data.frame(
        replica = r,
        t(sapply(dimensiones, function(d) theil_decomp(y[i], w[i], b[[d]][i])$total$S))
      )
    }
  }
  cat("Bootstrap", anio, "listo en", round(difftime(Sys.time(), inicio, units = "secs")), "s\n")
}

T_boot <- bind_rows(T_boot)
S_boot <- bind_rows(S_boot)

dir.create("outputs", showWarnings = FALSE)
write.csv(T_boot, "outputs/bootstrap_replicas_theil.csv", row.names = FALSE)
write.csv(S_boot, "outputs/bootstrap_replicas_S_2026.csv", row.names = FALSE)


# IC del 95 % del Theil de cada año ----

T_hat <- sapply(anios_theil, function(a) {
  b <- leer_final(a) %>% filter(en_poblacion, responde)
  theil_A(b$ingreso, b$fex_aj)
})

ic <- T_boot %>%
  group_by(anio) %>%
  summarise(ic_inf = quantile(T, 0.025), ic_sup = quantile(T, 0.975), ee_boot = sd(T), .groups = "drop") %>%
  mutate(T = T_hat[match(anio, anios_theil)], .after = anio)

write.csv(ic, "outputs/bootstrap_ic_theil.csv", row.names = FALSE)
print(ic)


# H2: ¿la educación explica más que cada una de las otras dimensiones en 2026? ----

h2 <- bind_rows(lapply(setdiff(dimensiones, "educ"), function(k) {
  dif <- S_boot$educ - S_boot[[k]]
  data.frame(comparacion = paste("educ -", k), media_dif = mean(dif),
             percentil_5 = unname(quantile(dif, 0.05)))
})) %>%
  mutate(supera = percentil_5 > 0)

write.csv(h2, "outputs/bootstrap_h2.csv", row.names = FALSE)
print(h2)
cat("Conclusión H2:", ifelse(all(h2$supera), "se rechaza H0: la educación explica más que todas las demás.",
                             "no se rechaza H0."), "\n")


# H3: ¿la desigualdad fue menor en 2026 que en 2018? ----

dif_T <- T_boot$T[T_boot$anio == 2026] - T_boot$T[T_boot$anio == 2018]
h3 <- data.frame(
  diferencia    = T_hat[anios_theil == 2026] - T_hat[anios_theil == 2018],   # tamaño de la diferencia
  percentil_95  = unname(quantile(dif_T, 0.95)),
  ic_inf_90     = unname(quantile(dif_T, 0.05))
) %>%
  mutate(decision = ifelse(percentil_95 < 0, "Se rechaza H0", "No se rechaza H0"))

write.csv(h3, "outputs/bootstrap_h3.csv", row.names = FALSE)
print(h3)


# Figura: Theil A por año con su IC del 95 % ----

g_ic <- ggplot(ic, aes(x = anio, y = T)) +
  geom_errorbar(aes(ymin = ic_inf, ymax = ic_sup), width = 0.2) +
  geom_point(size = 2, colour = "#2c7fb8") +
  scale_x_continuous(breaks = anios_theil) +
  labs(title = "Índice de Theil (estimador A) con intervalo de confianza del 95 %",
       subtitle = paste0("Bootstrap de personas, ", B, " réplicas. 2020 excluido."),
       x = NULL, y = "Theil") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())
ggsave("latex/fig_bootstrap_ic.png", g_ic, width = 8, height = 5, dpi = 300)

cat("06 listo\n")
