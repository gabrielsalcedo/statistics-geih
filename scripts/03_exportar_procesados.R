# =============================================================================
# ETAPA 2b — Exportar las bases analíticas a CSV comprimido
#
# Entrada: data/analitica/analitica_<año>.rds  (etapa 2)
# Salida:  data/processed/geih_<año>.csv.gz    (versionados en GitHub)
#          data/checksums.txt                  (huella MD5 de cada archivo)
#
# Solo hace falta correrlo si se reconstruyen las bases desde los microdatos.
# Al final comprueba que el CSV devuelve exactamente la misma base.
# =============================================================================


# Librerías ----

library(here)
library(dplyr)

source(here("R", "config.R"))
source(here("R", "datos.R"))


# Exportar y comprobar cada año ----

for (anio in anios) {

  base <- readRDS(here("data", "analitica", paste0("analitica_", anio, ".rds")))
  exportar_analitica(base, anio)

  # El CSV debe devolver la misma base, columna por columna y sin diferencias
  if (!isTRUE(all.equal(cargar_analitica(anio), base, tolerance = 0))) {
    stop("El CSV de ", anio, " no reproduce la base analítica.")
  }

  cat(anio, "| filas:", nrow(base), "| MB:",
      round(file.size(ruta_procesada(anio)) / 1e6, 1), "\n")
}


# Huellas MD5 ----
# Permiten comprobar que nadie tiene una copia dañada o incompleta
# (lo revisa scripts/00_verificar_datos.R).

archivos <- ruta_procesada(anios)
writeLines(
  paste(unname(tools::md5sum(archivos)), basename(archivos), sep = "  "),
  here("data", "checksums.txt")
)

cat("Listo: data/processed/ y data/checksums.txt\n")
