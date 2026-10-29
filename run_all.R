# =============================================================================
# run_all.R — Corre todo el proyecto en orden
#
# Abre statistics_geih.Rproj en RStudio y ejecuta:  source("run_all.R")
#
# Por defecto parte de data/processed/ (incluida en el repositorio), así que no
# necesita los microdatos del DANE. Con desde_crudos <- TRUE reconstruye primero
# las bases desde data/raw/ (ver data/raw/README.md).
# =============================================================================

desde_crudos <- FALSE


# Paquetes ----

paquetes <- c("here", "dplyr", "tidyr", "ggplot2", "scales", "quantreg", "testthat")
if (desde_crudos) paquetes <- c(paquetes, "haven")

faltan <- paquetes[!sapply(paquetes, requireNamespace, quietly = TRUE)]
if (length(faltan) > 0) {
  stop("Faltan paquetes. Instálalos con:\n  install.packages(c(",
       paste0('"', faltan, '"', collapse = ", "), "))")
}


# Pasos ----
# Cada script corre en su propio entorno para que no compartan variables.

correr <- function(script) {
  cat("\n==================== ", script, " ====================\n")
  inicio <- Sys.time()
  source(here::here("scripts", script), local = new.env())
  cat(">> ", script, " terminado en ", round(difftime(Sys.time(), inicio, units = "mins"), 1), " min\n", sep = "")
}

if (desde_crudos) {
  correr("01_base_cruda_anual.R")
  correr("02_base_analitica_anual.R")
  correr("02b_exportar_procesados.R")
}

correr("00_verificar_datos.R")
cat("\n==================== pruebas (tests/testthat) ====================\n")
testthat::test_dir(here::here("tests", "testthat"), stop_on_failure = TRUE)
correr("03_theil.R")
correr("04_estadistica_descriptiva.R")
correr("05_inferencia_clasica.R")

cat("\nListo. Resultados en data/resultados/, outputs/descriptiva/ y outputs/inferencia/.\n")
