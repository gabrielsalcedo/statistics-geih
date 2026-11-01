# =============================================================================
# correr_todo.R — Reproduce todo el proyecto
#
# Abrir statistics-geih.Rproj en RStudio y ejecutar:  source("scripts/correr_todo.R")
# Parte de las crudas que ya están en data/raw/ (no necesita los .dta del DANE).
# El paso 01 (extraer las crudas desde los .dta) NO se corre aquí.
# =============================================================================

# 1. Revisar que los paquetes estén instalados ----

paquetes <- c("dplyr", "tidyr", "ggplot2", "scales", "quantreg")
faltan   <- paquetes[!sapply(paquetes, requireNamespace, quietly = TRUE)]

if (length(faltan) > 0) {
  stop("Faltan paquetes. Instálalos con:\n  install.packages(c(",
       paste0('"', faltan, '"', collapse = ", "), "))")
}


# 2. Correr los scripts en orden ----

scripts <- c("02_bases_finales.R", "03_descriptiva.R", "04_theil_anual.R",
             "05_simulacion.R", "06_bootstrap.R")

inicio_total <- Sys.time()
for (s in scripts) {
  cat("\n==========", s, "==========\n")
  inicio <- Sys.time()
  source(file.path("scripts", s), local = new.env())   # cada script en su propio entorno
  cat(">>", s, "terminado en", round(difftime(Sys.time(), inicio, units = "mins"), 1), "min\n")
}

cat("\nListo en", round(difftime(Sys.time(), inicio_total, units = "mins"), 1), "min.",
    "Bases en data/final/, tablas en outputs/ y figuras en latex/.\n")
