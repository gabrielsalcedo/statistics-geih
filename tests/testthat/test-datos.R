# =============================================================================
# El CSV de data/processed/ debe devolver exactamente la base analítica (.rds).
# Se salta si no están los .rds (no se versionan; solo los tiene quien corrió 02).
# =============================================================================

source(here::here("R", "datos.R"))

test_that("cargar_analitica() reproduce cada .rds sin ninguna diferencia", {
  for (anio in 2018:2026) {
    rds <- here::here("data", "intermedia", "etapa2_analitica", paste0("analitica_", anio, ".rds"))
    skip_if_not(file.exists(rds), "No están las bases .rds.")
    expect_true(isTRUE(all.equal(cargar_analitica(anio), readRDS(rds), tolerance = 0)), info = anio)
  }
})

test_that("las categorías de datos.R son las de la base analítica", {
  b <- cargar_analitica(2024)
  expect_equal(levels(b$educ), niveles$educ)
  expect_true(is.ordered(b$educ) && is.ordered(b$estrato) && is.ordered(b$tam_empresa))
  expect_false(is.ordered(b$region))
  expect_false(anyNA(b$sexo))
})
