# =============================================================================
# Funciones del índice de Theil: los cuatro estimadores y la descomposición
#
# theil_decomp(): Theil T (GE(1)) ponderado, con descomposición between/within.
#                 Es la base de los estimadores A y B.
# theil_A(), theil_B(): estimadores por sustitución (con y sin pesos).
# theil_C(), theil_D(): estimadores lognormales (momentos y máxima verosimilitud).
#
# Sin efectos colaterales: este archivo solo define funciones. Lo usan
# scripts/03_theil.R y las pruebas de tests/testthat/.
# =============================================================================


# =============================================================================
# 1. THEIL POR SUSTITUCIÓN Y DESCOMPOSICIÓN
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
# 2. LOS CUATRO ESTIMADORES (devuelven un solo número)
# =============================================================================
# A y B: fórmula del Theil sobre los datos, con y sin factor de expansión.
# C y D: suponen ln(y) ~ Normal(m, sigma^2), de donde T = sigma^2 / 2.
#
# C y D aceptan pesos opcionales. Por defecto (w = NULL) no usan pesos, como
# están escritos en la propuesta. Si se usan con pesos o sin ellos en la
# simulación es una DECISIÓN DEL EQUIPO (docs/AUDITORIA.md, D2).

theil_A <- function(y, w) theil_decomp(y, w)$total$T

theil_B <- function(y) theil_decomp(y)$total$T


# Validación común de C y D ----

validar_y_w <- function(y, w) {
  if (is.null(w)) w <- rep(1, length(y))
  if (!is.numeric(y) || !is.numeric(w)) stop("y y w deben ser numéricos.")
  if (length(w) != length(y))           stop("y y w tienen longitudes distintas.")
  if (anyNA(y) || anyNA(w))             stop("Hay NA en y o en w.")
  if (any(y <= 0))                      stop("Todos los ingresos deben ser > 0.")
  if (any(w < 0))                       stop("Hay pesos negativos.")
  if (sum(w) == 0)                      stop("La suma de los pesos es 0.")
  w
}


# C: lognormal por método de momentos ----
# Se igualan la media y la varianza de la muestra con las de una lognormal:
#   E(y) = exp(m + sigma^2/2),  Var(y) = E(y)^2 * (exp(sigma^2) - 1)
#   => sigma^2 = ln(1 + CV^2),  con CV = desviación / media.
# Momentos de la muestra: la varianza divide por n (o por W con pesos),
# no por n - 1, porque así se define el método de momentos.

theil_C <- function(y, w = NULL) {
  w     <- validar_y_w(y, w)
  media <- sum(w * y) / sum(w)
  var_y <- sum(w * (y - media)^2) / sum(w)
  sigma2 <- log(1 + var_y / media^2)
  sigma2 / 2
}


# D: lognormal por máxima verosimilitud ----
# El EMV de sigma^2 es la varianza de ln(y) dividiendo por n (o por W).
# OJO: var() de R divide por n - 1; por eso no se usa aquí.

theil_D <- function(y, w = NULL) {
  w      <- validar_y_w(y, w)
  ly     <- log(y)
  m      <- sum(w * ly) / sum(w)
  sigma2 <- sum(w * (ly - m)^2) / sum(w)
  sigma2 / 2
}
