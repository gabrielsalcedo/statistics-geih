# =============================================================================
# 04 — Theil anual y descomposición por dimensión
#
# Para cada año con ingreso (2018–2026, sin 2020):
#   - Theil total con tres pesos: fex_aj (estimador A, principal), FEX (A sin
#     ajuste por no respuesta) y sin pesos (estimador B), como sensibilidad.
#   - Descomposición entre/dentro por educación, formalidad, sexo, región y estrato.
#
# Entrada: data/final/geih_<año>.csv.gz
# Salida:  outputs/theil_*.csv  y  latex/fig_theil_anual.png, latex/fig_descomposicion.png
# =============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)

source("scripts/00_funciones.R")   # theil_decomp(), leer_final()

anios_theil <- c(2018, 2019, 2021:2026)   # 2020 excluido: sin ingreso ni estrato (pandemia)
dimensiones <- c("educ", "formal", "sexo", "region", "estrato")
pesos       <- c("fex_aj", "FEX", "sin_pesos")


# Cálculo por año ----

resumen <- list()
grupos  <- list()

for (anio in anios_theil) {

  b <- leer_final(anio) %>% filter(en_poblacion, responde) %>% mutate(sin_pesos = 1)

  for (p in pesos) {
    tot <- theil_decomp(b$ingreso, b[[p]])$total
    resumen[[paste(anio, p, "total")]] <- data.frame(anio = anio, peso = p, dimension = "total", tot)

    for (d in dimensiones) {
      res <- theil_decomp(b$ingreso, b[[p]], b[[d]])
      resumen[[paste(anio, p, d)]] <- data.frame(anio = anio, peso = p, dimension = d, res$total)
      grupos[[paste(anio, p, d)]]  <- data.frame(anio = anio, peso = p, dimension = d, res$grupos)
    }
  }
  cat("Theil", anio, "listo |", nrow(b), "ocupados\n")
}

theil_resumen <- bind_rows(resumen)
theil_grupos  <- bind_rows(grupos)

dir.create("outputs", showWarnings = FALSE)
write.csv(theil_resumen, "outputs/theil_resumen.csv", row.names = FALSE)
write.csv(theil_grupos,  "outputs/theil_grupos.csv",  row.names = FALSE)


# Tablas para el informe ----

# Theil total por año con los tres pesos
theil_por_anio <- theil_resumen %>%
  filter(dimension == "total") %>%
  select(anio, peso, T) %>%
  mutate(T = round(T, 4)) %>%
  pivot_wider(names_from = peso, values_from = T)
write.csv(theil_por_anio, "outputs/theil_por_anio.csv", row.names = FALSE)
print(theil_por_anio)

# Porcentaje de la desigualdad explicado por cada dimensión (componente entre), con fex_aj
participacion <- theil_resumen %>%
  filter(peso == "fex_aj", dimension != "total") %>%
  select(anio, dimension, S) %>%
  mutate(S = round(100 * S, 1)) %>%
  pivot_wider(names_from = dimension, values_from = S)
write.csv(participacion, "outputs/theil_participacion_entre.csv", row.names = FALSE)
print(participacion)


# Figuras ----

tema <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank(),
        legend.position = "bottom")

g_anual <- theil_resumen %>%
  filter(dimension == "total") %>%
  mutate(peso = recode(peso, fex_aj = "A (fex_aj)", FEX = "A sin ajuste (FEX)", sin_pesos = "B (sin pesos)")) %>%
  ggplot(aes(x = anio, y = T, colour = peso)) +
  geom_line() + geom_point() +
  geom_vline(xintercept = 2021.5, linetype = "dotted") +
  annotate("text", x = 2021.6, y = Inf, label = "cambio de marco", hjust = 0, vjust = 1.5, size = 3) +
  scale_x_continuous(breaks = anios_theil) +
  labs(title = "Índice de Theil del ingreso laboral, 2018–2026 (sin 2020)",
       x = NULL, y = "Theil", colour = NULL) +
  tema
ggsave("latex/fig_theil_anual.png", g_anual, width = 8, height = 5, dpi = 300)

g_desc <- theil_resumen %>%
  filter(peso == "fex_aj", dimension != "total") %>%
  ggplot(aes(x = anio, y = 100 * S, colour = dimension)) +
  geom_line() + geom_point() +
  scale_x_continuous(breaks = anios_theil) +
  labs(title = "Porcentaje de la desigualdad explicado por cada dimensión (entre grupos)",
       x = NULL, y = "% del Theil total", colour = NULL) +
  tema
ggsave("latex/fig_descomposicion.png", g_desc, width = 8, height = 5, dpi = 300)

cat("04 listo\n")
