# =============================================================================
# 00 — Verificar que las bases descargadas del repositorio están completas
#
# Para quien clona el repositorio y NO tiene los microdatos del DANE.
# Comprueba, año por año, que:
#   1. data/analitica/analitica_<año>.rds tiene las mismas filas que la
#      base cruda unida (data/final/base_<año>.rds) y en el mismo orden.
#   2. Los conteos de población coinciden con el reporte de trazabilidad.
#   3. El ajuste por no respuesta (fex_aj) conserva el total del FEX.
#   4. El Theil total ponderado (estimador A, fex_aj) coincide con
#      data/resultados/theil_resumen.csv.
#
# Si todo sale "OK", tienes exactamente los mismos datos con los que se
# calcularon los resultados y puedes correr 03_theil.R y 04_estadistica_descriptiva.R.
# Solo usa R base (+ here, si está instalado).
# =============================================================================

ruta <- function(...) {
  if (requireNamespace("here", quietly = TRUE)) here::here(...) else file.path(...)
}

anios <- 2018:2026

theil_A <- function(y, w) {
  mu <- sum(w * y) / sum(w)
  r  <- y / mu
  sum(w * r * log(r)) / sum(w)
}

resumen <- read.csv(ruta("data", "resultados", "theil_resumen.csv"))
llaves  <- c("MES", "DIRECTORIO", "SECUENCIA_P", "HOGAR", "ORDEN")
ok_todo <- TRUE

chequear <- function(condicion, texto) {
  cat(if (condicion) "  OK    " else "  FALLA ", texto, "\n")
  if (!condicion) ok_todo <<- FALSE
}

for (anio in anios) {

  cat("\n----", anio, "----\n")

  cruda <- readRDS(ruta("data", "final",     paste0("base_", anio, ".rds")))
  a     <- readRDS(ruta("data", "analitica", paste0("analitica_", anio, ".rds")))
  traz  <- read.csv(ruta("data", "analitica", "reportes", paste0("trazabilidad_", anio, ".csv")))

  # 1. Ninguna fila se perdió entre la etapa 1 y la etapa 2
  chequear(nrow(a) == nrow(cruda), paste("filas analítica = filas base cruda:", nrow(a)))
  chequear(all(a[llaves] == cruda[llaves]), "mismas personas y en el mismo orden")
  chequear(!anyDuplicated(a[llaves]), "sin duplicados (MES + llaves de persona)")

  # 2. Población de estudio = reporte de trazabilidad
  chequear(sum(a$en_poblacion) == traz$filas[traz$paso == "5. Dimensiones completas"],
           paste("en_poblacion:", sum(a$en_poblacion)))
  chequear(sum(a$en_poblacion & a$responde) == traz$filas[grepl("^6", traz$paso)],
           paste("entran al Theil (en_poblacion & responde):", sum(a$en_poblacion & a$responde)))

  # 3. El ajuste por no respuesta reparte el peso, no lo crea ni lo destruye
  p <- a[a$en_poblacion, ]
  chequear(abs(sum(p$fex_aj) - sum(p$FEX)) < 1e-6 * sum(p$FEX), "suma fex_aj = suma FEX")
  chequear(all(p$fex_aj[!p$responde] == 0), "no respondientes con fex_aj = 0")

  # 4. Theil total (estimador A) = resultado guardado
  if (anio != 2020) {
    d   <- a[a$en_poblacion & a$responde, ]
    T_A <- theil_A(d$ingreso, d$fex_aj)
    ref <- resumen$T[resumen$anio == anio & resumen$peso == "fex_aj" & resumen$dimension == "total"]
    chequear(abs(T_A - ref) < 1e-10, sprintf("Theil A = %.4f (guardado: %.4f)", T_A, ref))
  } else {
    cat("  --    2020 excluido del Theil (ingreso faltante en la recolección telefónica)\n")
  }
}

cat("\n", if (ok_todo) "TODO CORRECTO: los datos están completos." else "HAY FALLAS: revisa los mensajes de arriba.", "\n")
