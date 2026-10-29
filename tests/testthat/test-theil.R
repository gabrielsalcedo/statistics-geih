# =============================================================================
# Pruebas de R/theil.R con respuestas que se pueden verificar a mano.
# Correr desde la raíz del proyecto:  testthat::test_dir("tests/testthat")
# =============================================================================


# 1. Casos extremos ----

test_that("ingresos iguales => T = 0 en los cuatro estimadores", {
  y <- rep(5, 10)
  expect_equal(theil_A(y, 1:10), 0)
  expect_equal(theil_B(y), 0)
  expect_equal(theil_C(y), 0)
  expect_equal(theil_D(y), 0)
})

test_that("una persona con todo el ingreso entre n => T = ln(n)", {
  # El Theil admite ingresos 0 en el límite (0·ln 0 = 0), pero la función exige
  # y > 0. Por eso se usa un ingreso casi nulo para los demás.
  for (n in c(2, 10, 1000)) {
    y <- c(1, rep(1e-12, n - 1))
    expect_equal(theil_B(y), log(n), tolerance = 1e-6)
  }
})


# 2. Ejemplos hechos a mano (antes estaban en scripts/03_theil.R) ----

test_that("ejemplo 1: cuatro personas sin pesos", {
  # T = 0,173 | between = 0,131 | within = 0,043
  r <- theil_decomp(c(1, 1, 2, 4), g = c("Bachiller", "Bachiller", "Universitario", "Universitario"))$total
  expect_equal(r$T,   0.1733, tolerance = 1e-4)
  expect_equal(r$T_B, 0.1308, tolerance = 1e-4)
  expect_equal(r$T_W, 0.0425, tolerance = 1e-4)
})

test_that("ejemplo 2: cinco personas con pesos", {
  # mu = 3 | T = 0,3684 | between = 0,2908 | within = 0,0776
  r <- theil_decomp(c(1, 2, 3, 6, 9), c(4, 1, 1, 1, 1),
                    c("Informal", "Informal", "Formal", "Formal", "Formal"))$total
  expect_equal(r$mu,  3)
  expect_equal(r$T,   0.3684, tolerance = 1e-4)
  expect_equal(r$T_B, 0.2908, tolerance = 1e-4)
  expect_equal(r$T_W, 0.0776, tolerance = 1e-4)
})

test_that("T de dos personas con ingresos 1 y 3 coincide con la fórmula escrita", {
  # mu = 2: T = (1/2)[(1/2)ln(1/2) + (3/2)ln(3/2)]
  expect_equal(theil_B(c(1, 3)), 0.5 * (0.5 * log(0.5) + 1.5 * log(1.5)))
})


# 3. Invarianza a la escala ----

test_that("multiplicar los ingresos por c no cambia ningún estimador", {
  set.seed(1)
  y <- rlnorm(200, 13, 0.8)
  w <- runif(200, 100, 2000)
  for (c in c(0.001, 1e6)) {
    expect_equal(theil_A(c * y, w), theil_A(y, w))
    expect_equal(theil_B(c * y),    theil_B(y))
    expect_equal(theil_C(c * y),    theil_C(y))
    expect_equal(theil_D(c * y),    theil_D(y))
  }
})

test_that("multiplicar todos los pesos por c no cambia A", {
  y <- c(1, 2, 3, 6, 9); w <- c(4, 1, 1, 1, 1)
  expect_equal(theil_A(y, w / 6), theil_A(y, w))
})


# 4. Relación entre A y B ----

test_that("A con todos los pesos = 1 es igual a B", {
  set.seed(2)
  y <- rlnorm(300)
  expect_equal(theil_A(y, rep(1, 300)), theil_B(y))
})

test_that("A con pesos enteros = B sobre los datos con filas repetidas", {
  y <- c(1, 2, 3, 6, 9); w <- c(4, 1, 1, 1, 1)
  expect_equal(theil_A(y, w), theil_B(rep(y, times = w)))
  set.seed(3)
  y <- rlnorm(50); w <- sample(1:7, 50, replace = TRUE)
  expect_equal(theil_A(y, w), theil_B(rep(y, times = w)))
  # Lo mismo vale para C y D con pesos
  expect_equal(theil_C(y, w), theil_C(rep(y, times = w)))
  expect_equal(theil_D(y, w), theil_D(rep(y, times = w)))
})


# 5. Descomposición ----

test_that("between + within = total y within = suma de s_k * T_k", {
  set.seed(4)
  y <- rlnorm(1000, 13, 1); w <- runif(1000, 50, 3000)
  g <- sample(c("a", "b", "c", "d"), 1000, replace = TRUE)
  r <- theil_decomp(y, w, g)
  expect_equal(r$total$T_B + r$total$T_W, r$total$T, tolerance = 1e-12)
  expect_equal(sum(r$grupos$s_k * r$grupos$T_k), r$total$T_W)
  expect_equal(sum(r$grupos$s_k), 1)                       # las participaciones suman 1
  # T_k de cada grupo = Theil del grupo calculado por separado
  for (k in r$grupos$grupo) {
    expect_equal(r$grupos$T_k[r$grupos$grupo == k], theil_A(y[g == k], w[g == k]))
  }
})

test_that("con un solo grupo, between = 0", {
  y <- c(1, 2, 3, 6, 9)
  r <- theil_decomp(y, g = rep("todos", 5))$total
  expect_equal(r$T_B, 0)
  expect_equal(r$T_W, r$T)
})


# 6. Lognormal con sigma conocido ----

test_that("con datos lognormales, C y D se acercan a sigma^2 / 2", {
  set.seed(5)
  for (s in c(0.5, 1)) {
    y <- rlnorm(1e6, meanlog = 13, sdlog = s)
    expect_equal(theil_D(y), s^2 / 2, tolerance = 0.01)
    expect_equal(theil_C(y), s^2 / 2, tolerance = 0.02)   # C es más ruidoso: depende de la cola
    expect_equal(theil_B(y), s^2 / 2, tolerance = 0.02)   # y el Theil empírico también converge
  }
})

test_that("D divide por n (EMV), no por n - 1 como var()", {
  y <- c(1, 2, 4, 8)
  expect_equal(theil_D(y), mean((log(y) - mean(log(y)))^2) / 2)
  expect_false(isTRUE(all.equal(theil_D(y), var(log(y)) / 2)))
})


# 7. Validaciones ----

test_that("NA, ingresos no positivos y pesos inválidos detienen el cálculo", {
  for (f in list(function(y, w) theil_A(y, w), theil_C, theil_D)) {
    expect_error(f(c(1, NA, 3), c(1, 1, 1)))
    expect_error(f(c(1, 0, 3),  c(1, 1, 1)))
    expect_error(f(c(1, -2, 3), c(1, 1, 1)))
    expect_error(f(c(1, 2, 3),  c(1, -1, 1)))
    expect_error(f(c(1, 2, 3),  c(0, 0, 0)))
    expect_error(f(c(1, 2, 3),  c(1, 1)))
  }
})

test_that("una persona con peso 0 no cambia el resultado", {
  y <- c(1, 2, 3, 6, 9); w <- c(4, 1, 1, 1, 1)
  expect_equal(theil_A(c(y, 1000), c(w, 0)), theil_A(y, w))
  expect_equal(theil_D(c(y, 1000), c(w, 0)), theil_D(y, w))
})
