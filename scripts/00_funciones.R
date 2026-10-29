# =============================================================================
# 00 — Funciones del proyecto
#
# Lo usan todos los demás scripts con source("scripts/00_funciones.R").
#   1. Los cuatro estimadores del índice de Theil (A, B, C, D) y la
#      descomposición entre/dentro, como en la primera entrega.
#   2. Leer y escribir las bases en CSV comprimido (data/raw y data/final).
#   3. Verificaciones con ejemplos que se pueden comprobar a mano.
# =============================================================================


# =============================================================================
# 1. ÍNDICE DE THEIL
# =============================================================================

# Theil ponderado y descomposición ----
# y: ingresos (> 0, sin NA)
# w: factor de expansión (>= 0). NULL = todos iguales a 1 (estimador B).
# g: grupos. NULL = solo el Theil total.
#
# T = (1/W) Σ w_i (y_i/μ) ln(y_i/μ),  con W = Σ w_i  y  μ = media ponderada.
# Entre  = Σ s_k ln(μ_k/μ)
# Dentro = Σ s_k T_k,  donde s_k es la participación del grupo k en el ingreso.

theil_decomp <- function(y, w = NULL, g = NULL) {

  if (is.null(w)) w <- rep(1, length(y))
  if (anyNA(y) || anyNA(w)) stop("Hay NA en el ingreso o en los pesos.")
  if (any(y <= 0))          stop("Todos los ingresos deben ser > 0 (ln(0) no existe).")

  # Theil total
  W  <- sum(w)                    # población representada
  mu <- sum(w * y) / W            # ingreso medio ponderado
  r  <- y / mu                    # ingreso relativo
  T  <- sum(w * r * log(r)) / W

  # n_ef: tamaño de muestra efectivo de Kish (cuánta precisión se pierde por los pesos)
  total <- data.frame(T = T, n = length(y), W = W, mu = mu, n_ef = W^2 / sum(w^2))
  if (is.null(g)) return(list(total = total))

  # Por grupo
  g    <- droplevels(as.factor(g))
  W_k  <- tapply(w, g, sum)
  mu_k <- tapply(w * y, g, sum) / W_k
  T_k  <- sapply(levels(g), function(k) {
    i   <- g == k
    r_k <- y[i] / mu_k[[k]]
    sum(w[i] * r_k * log(r_k)) / W_k[[k]]
  })

  p_k <- W_k / W                  # participación en la población
  s_k <- p_k * mu_k / mu          # participación en el ingreso

  entre  <- sum(s_k * log(mu_k / mu))
  dentro <- sum(s_k * T_k)

  # La descomposición es exacta: entre + dentro = total
  if (abs(T - (entre + dentro)) > 1e-9 * max(1, T)) stop("La descomposición no cuadra.")

  list(
    total  = cbind(total, T_B = entre, T_W = dentro, S = entre / T),
    grupos = data.frame(grupo = levels(g), n_k = as.vector(table(g)),
                        p_k = as.vector(p_k), mu_k = as.vector(mu_k),
                        s_k = as.vector(s_k), T_k = as.vector(T_k),
                        aporte_between = as.vector(s_k * log(mu_k / mu)),
                        aporte_within  = as.vector(s_k * T_k))
  )
}


# Los cuatro estimadores ----
# A: Theil con el factor de expansión.
# B: el mismo Theil sin factor (todos los pesos = 1).
# C y D suponen ln(y) ~ Normal(m, σ²), de donde T = σ²/2. Sin ponderar.
#   C (momentos):  σ² = ln(1 + CV²), CV = desviación / media (divisor n).
#   D (máxima verosimilitud): σ² = (1/n) Σ (ln y_i - media de ln y)²  (divisor n, no n - 1).

theil_A <- function(y, w) theil_decomp(y, w)$total$T

theil_B <- function(y) theil_decomp(y)$total$T

theil_C <- function(y) {
  media <- mean(y)
  var_y <- mean((y - media)^2)          # divisor n
  log(1 + var_y / media^2) / 2
}

theil_D <- function(y) {
  ly <- log(y)
  mean((ly - mean(ly))^2) / 2           # divisor n
}


# =============================================================================
# 2. LEER Y ESCRIBIR LAS BASES (CSV comprimido)
# =============================================================================

# Escribir ----
# Los números con decimales (factores de expansión) se escriben con 17 cifras
# para que, al leerlos, sean exactamente los mismos.

escribir_csv_gz <- function(d, ruta) {
  d <- as.data.frame(d)
  con_comillas <- which(sapply(d, function(x) is.character(x) || is.factor(x)))
  for (v in names(d)) {
    if (is.double(d[[v]])) d[[v]] <- sprintf("%.17g", d[[v]])
    if (is.factor(d[[v]])) d[[v]] <- as.character(d[[v]])
  }
  con <- gzfile(ruta, "w", encoding = "UTF-8")
  write.csv(d, con, row.names = FALSE, na = "NA", quote = con_comillas)
  close(con)
}


# Leer una cruda (data/raw/geih_cruda_<año>.csv.gz) ----

leer_cruda <- function(anio) {
  texto <- c("DIRECTORIO", "SECUENCIA_P", "HOGAR", "ORDEN",
             "FEX_FUENTE", "EDUC_FUENTE", "TAM_EMPRESA_FUENTE")
  d <- read.csv(gzfile(paste0("data/raw/geih_cruda_", anio, ".csv.gz"), encoding = "UTF-8"),
                colClasses = c(ANIO = "integer", MES = "integer",
                               setNames(rep("character", length(texto)), texto)),
                na.strings = "NA", encoding = "UTF-8")
  dplyr::as_tibble(d)
}


# Leer una base final (data/final/geih_<año>.csv.gz) ----
# En un CSV las categorías se guardan como texto; aquí se les devuelve el orden.

niveles <- list(
  sexo        = c("Hombre", "Mujer"),
  educ        = c("Ninguno/preescolar", "Primaria", "Secundaria", "Media", "Superior"),
  formal      = c("Formal", "Informal"),
  region      = c("Bogotá", "Caribe", "Oriental", "Central", "Pacífica", "Orinoquía-Amazonía"),
  estrato     = as.character(1:6),
  posicion    = c("Asalariado privado", "Gobierno", "Doméstico",
                  "Cuenta propia", "Patrón", "Sin remuneración"),
  tam_empresa = c("Trabaja solo", "2 a 5", "6 a 10", "11 a 50", "51 o más")
)

leer_final <- function(anio) {
  d <- read.csv(gzfile(paste0("data/final/geih_", anio, ".csv.gz"), encoding = "UTF-8"),
                colClasses = c(ANIO = "integer", MES = "integer",
                               DIRECTORIO = "character", SECUENCIA_P = "character",
                               HOGAR = "character", ORDEN = "character", celda_aj = "character"),
                na.strings = "NA", encoding = "UTF-8")
  for (v in names(niveles)) {
    d[[v]] <- factor(d[[v]], levels = niveles[[v]],
                     ordered = v %in% c("educ", "estrato", "tam_empresa"))
  }
  dplyr::as_tibble(d)
}


# =============================================================================
# 3. VERIFICACIONES (si alguna falla, el script se detiene)
# =============================================================================

# Ingresos iguales: no hay desigualdad
stopifnot(theil_B(rep(5, 10)) == 0, theil_C(rep(5, 10)) == 0, theil_D(rep(5, 10)) == 0)

# A con todos los pesos iguales a 1 es exactamente B
stopifnot(abs(theil_A(c(1, 2, 3, 6, 9), rep(1, 5)) - theil_B(c(1, 2, 3, 6, 9))) < 1e-12)

# Ejemplo de la clase hecho a mano: T = 0,1733, entre = 0,1308, dentro = 0,0425
ej <- theil_decomp(c(1, 1, 2, 4), g = c("Bachiller", "Bachiller", "Universitario", "Universitario"))$total
stopifnot(abs(ej$T - 0.1733) < 1e-4, abs(ej$T_B - 0.1308) < 1e-4, abs(ej$T_W - 0.0425) < 1e-4)

# Entre + dentro = total, con pesos
ej <- theil_decomp(c(1, 2, 3, 6, 9), c(4, 1, 1, 1, 1), c("I", "I", "F", "F", "F"))$total
stopifnot(abs(ej$T_B + ej$T_W - ej$T) < 1e-12)
rm(ej)
