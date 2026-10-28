# =============================================================================
# ETAPA 3 — Índice de Theil y su descomposición
#
# 1. theil_decomp(): Theil T (GE(1)) ponderado, con descomposición
#    between / within opcional.
# 2. Pruebas con los ejemplos hechos a mano (si fallan, el código se detiene).
# 3. Aplicación a cada año (sin 2020), con tres pesos para sensibilidad.
#
# Entrada: data/analitica/analitica_<año>.rds  (etapa 2)
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
# Argumentos:
#   y: ingresos (> 0, sin NA)
#   w: pesos (>= 0, sin NA). NULL = todos iguales a 1 (estimador B).
#   g: grupos (sin NA). NULL = solo el Theil total.
#
# Devuelve una lista:
#   $total:  T, n, W, mu, n_ef y, si hay g, T_B, T_W y S
#   $grupos: por grupo: n, p_k, mu_k, s_k, T_k y su aporte al between y al within
#
# Cada línea corresponde a una columna del cálculo a mano.

theil_decomp <- function(y, w = NULL, g = NULL, tol = 1e-9) {
  
  
  # Validaciones ----
  
  if (is.null(w)) w <- rep(1, length(y))
  
  if (!is.numeric(y) || !is.numeric(w)) stop("y y w deben ser numéricos.")
  if (length(w) != length(y))           stop("y y w tienen longitudes distintas.")
  if (anyNA(y) || anyNA(w))             stop("Hay NA en y o en w.")
  if (any(y <= 0))                      stop("Todos los ingresos deben ser > 0 (ln(0) no existe).")
  if (any(w < 0))                       stop("Hay pesos negativos.")
  if (sum(w) == 0)                      stop("La suma de los pesos es 0.")
  
  if (!is.null(g)) {
    if (length(g) != length(y)) stop("g y y tienen longitudes distintas.")
    if (anyNA(g))               stop("Hay NA en g.")
    g <- droplevels(as.factor(g))       # conserva el orden de los niveles y quita los vacíos
  }
  
  
  # Theil total ----
  
  W  <- sum(w)                  # población representada
  mu <- sum(w * y) / W          # media ponderada
  r  <- y / mu                  # ingreso relativo
  T  <- sum(w * r * log(r)) / W # promedio ponderado de r·ln(r)
  
  total <- data.frame(
    T    = T,
    n    = length(y),
    W    = W,
    mu   = mu,
    n_ef = W^2 / sum(w^2)       # tamaño de muestra efectivo de Kish
  )
  
  if (is.null(g)) return(list(total = total))
  
  
  # Resumen por grupo ----
  
  W_k  <- tapply(w, g, sum)
  mu_k <- tapply(w * y, g, sum) / W_k
  
  T_k <- sapply(levels(g), function(k) {
    i   <- g == k
    r_k <- y[i] / mu_k[[k]]     # ingreso relativo a la media del grupo
    sum(w[i] * r_k * log(r_k)) / W_k[[k]]
  })
  
  p_k <- W_k / W                # participación en la población
  s_k <- p_k * mu_k / mu        # participación en el ingreso
  
  
  # Descomposición ----
  
  aporte_between <- s_k * log(mu_k / mu)
  aporte_within  <- s_k * T_k
  
  T_B <- sum(aporte_between)
  T_W <- sum(aporte_within)
  
  
  # Chequeo: la descomposición debe ser exacta ----
  
  if (abs(T - (T_B + T_W)) > tol * max(1, T)) {
    stop("La descomposición no cuadra: T = ", T, ", T_B + T_W = ", T_B + T_W)
  }
  
  total$T_B <- T_B
  total$T_W <- T_W
  total$S   <- T_B / T
  
  grupos <- data.frame(
    grupo          = levels(g),
    n_k            = as.vector(table(g)),
    p_k            = as.vector(p_k),
    mu_k           = as.vector(mu_k),
    s_k            = as.vector(s_k),
    T_k            = as.vector(T_k),
    aporte_between = as.vector(aporte_between),
    aporte_within  = as.vector(aporte_within)
  )
  
  list(total = total, grupos = grupos)
}


# =============================================================================
# 2. PRUEBAS CON LOS EJEMPLOS HECHOS A MANO
# =============================================================================

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

anios_theil <- setdiff(2018:2026, 2020)   # 2020 excluido: ingreso no registrado en la pandemia

dimensiones <- c("educ", "formal", "sexo", "region", "estrato")

# Pesos para el análisis de sensibilidad:
#   fex_aj:    estimador A con ajuste por no respuesta (principal)
#   FEX:       estimador A sin ajuste (casos completos)
#   sin_pesos: estimador B
pesos <- c("fex_aj", "FEX", "sin_pesos")


calcular_theil_anio <- function(anio) {
  
  b <- readRDS(here("data", "analitica", paste0("analitica_", anio, ".rds"))) %>%
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
