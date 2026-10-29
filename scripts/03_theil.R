# =============================================================================
# ETAPA 3 — Índice de Theil y su descomposición
#
# 1. theil_decomp(): Theil T (GE(1)) ponderado, con descomposición
#    between / within opcional.
# 2. Pruebas con los ejemplos hechos a mano (si fallan, el código se detiene).
# 3. Aplicación a cada año (sin 2020), con tres pesos para sensibilidad.
#
# Entrada: data/processed/geih_<año>.csv.gz    (etapa 2, versionada en GitHub)
# Salida:  data/resultados/theil_resumen.csv   (un renglón por año, peso y dimensión)
#          data/resultados/theil_grupos.csv    (detalle de cada grupo)
# =============================================================================


# Librerías ----

library(here)
library(dplyr)

dir.create(here("data", "resultados"), showWarnings = FALSE, recursive = TRUE)


# =============================================================================
# 1. FUNCIÓN
# =============================================================================
# theil_decomp() está en R/theil.R (junto con los estimadores C y D).

source(here("R", "theil.R"))
source(here("R", "config.R"))   # anios_theil y dimensiones
source(here("R", "datos.R"))    # cargar_analitica()


# =============================================================================
# 2. PRUEBAS CON LOS EJEMPLOS HECHOS A MANO
# =============================================================================
# Las pruebas completas están en tests/testthat/. Estas se dejan aquí para que
# el script se detenga si la función se rompe.

# Ejemplo 1: cuatro personas sin pesos ----
# T = 0,173 | between = 0,131 | within = 0,043

ej1 <- theil_decomp(
  y = c(1, 1, 2, 4),
  g = c("Bachiller", "Bachiller", "Universitario", "Universitario")
)

stopifnot(
  abs(ej1$total$T   - 0.1733) < 1e-4,
  abs(ej1$total$T_B - 0.1308) < 1e-4,
  abs(ej1$total$T_W - 0.0425) < 1e-4
)


# Ejemplo 2: cinco personas con pesos ----
# mu = 3 | T = 0,3684 | between = 0,2908 | within = 0,0776 | S = 79 %

ej2 <- theil_decomp(
  y = c(1, 2, 3, 6, 9),
  w = c(4, 1, 1, 1, 1),
  g = c("Informal", "Informal", "Formal", "Formal", "Formal")
)

stopifnot(
  abs(ej2$total$mu  - 3)      < 1e-12,
  abs(ej2$total$T   - 0.3684) < 1e-4,
  abs(ej2$total$T_B - 0.2908) < 1e-4,
  abs(ej2$total$T_W - 0.0776) < 1e-4
)


# Prueba de los pesos: repetir a cada persona w veces = Theil ponderado ----

ej2_expandido <- theil_decomp(y = rep(c(1, 2, 3, 6, 9), times = c(4, 1, 1, 1, 1)))

stopifnot(abs(ej2_expandido$total$T - ej2$total$T) < 1e-12)


# Prueba de invarianza a la escala: multiplicar ingresos o pesos no cambia T ----

stopifnot(
  abs(theil_decomp(c(1, 2, 3, 6, 9) * 1e6, c(4, 1, 1, 1, 1))$total$T - ej2$total$T) < 1e-12,
  abs(theil_decomp(c(1, 2, 3, 6, 9), c(4, 1, 1, 1, 1) / 6)$total$T   - ej2$total$T) < 1e-12
)

cat("Pruebas de theil_decomp(): todas correctas.\n")


# =============================================================================
# 3. APLICACIÓN A CADA AÑO
# =============================================================================

# anios_theil (sin 2020) y dimensiones vienen de R/config.R

# Pesos para el análisis de sensibilidad:
#   fex_aj:    estimador A con ajuste por no respuesta (principal)
#   FEX:       estimador A sin ajuste (casos completos)
#   sin_pesos: estimador B
pesos <- c("fex_aj", "FEX", "sin_pesos")


calcular_theil_anio <- function(anio) {
  
  b <- cargar_analitica(anio) %>%
    filter(en_poblacion, responde) %>%
    mutate(sin_pesos = 1)
  
  resumen <- list()
  grupos  <- list()
  
  for (p in pesos) {
    
    # Total ----
    
    tot <- theil_decomp(b$ingreso, b[[p]])$total
    resumen[[paste(p, "total")]] <- data.frame(anio = anio, peso = p, dimension = "total", tot)
    
    
    # Descomposiciones ----
    
    for (d in dimensiones) {
      
      res <- theil_decomp(b$ingreso, b[[p]], b[[d]])
      
      resumen[[paste(p, d)]] <- data.frame(anio = anio, peso = p, dimension = d, res$total)
      grupos[[paste(p, d)]]  <- data.frame(anio = anio, peso = p, dimension = d, res$grupos)
    }
  }
  
  cat("Theil", anio, "listo |", nrow(b), "ocupados\n")
  
  list(resumen = bind_rows(resumen), grupos = bind_rows(grupos))
}


resultados <- lapply(anios_theil, calcular_theil_anio)

theil_resumen <- bind_rows(lapply(resultados, `[[`, "resumen"))
theil_grupos  <- bind_rows(lapply(resultados, `[[`, "grupos"))

write.csv(theil_resumen, here("data", "resultados", "theil_resumen.csv"), row.names = FALSE)
write.csv(theil_grupos,  here("data", "resultados", "theil_grupos.csv"),  row.names = FALSE)


# =============================================================================
# 4. TABLAS PARA REVISAR
# =============================================================================

# Theil total por año con los tres pesos (sensibilidad) ----

cat("\nTheil total por año y peso:\n")
theil_resumen %>%
  filter(dimension == "total") %>%
  select(anio, peso, T) %>%
  mutate(T = round(T, 4)) %>%
  tidyr::pivot_wider(names_from = peso, values_from = T) %>%
  print()


# % explicado por cada dimensión (S), con fex_aj ----

cat("\nPorcentaje explicado (between / total), fex_aj:\n")
theil_resumen %>%
  filter(peso == "fex_aj", dimension != "total") %>%
  select(anio, dimension, S) %>%
  mutate(S = round(100 * S, 1)) %>%
  tidyr::pivot_wider(names_from = dimension, values_from = S) %>%
  print()


# Tamaño efectivo de Kish: pérdida de precisión por el ajuste ----

cat("\nTamaño de muestra efectivo:\n")
theil_resumen %>%
  filter(dimension == "total", peso != "sin_pesos") %>%
  select(anio, peso, n, n_ef) %>%
  mutate(n_ef = round(n_ef)) %>%
  tidyr::pivot_wider(names_from = peso, values_from = n_ef) %>%
  print()
