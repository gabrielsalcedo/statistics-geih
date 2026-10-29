# =============================================================================
# 00 — Verificar que las bases del repositorio están completas
#
# Para quien clona el repositorio y NO tiene los microdatos del DANE.
# Comprueba, año por año, que data/processed/geih_<año>.csv.gz:
#   1. No está dañado ni incompleto (huella MD5 = data/checksums.txt).
#   2. No tiene personas repetidas (MES + llaves de persona).
#   3. Tiene los mismos conteos que el reporte de trazabilidad.
#   4. Tiene un ajuste por no respuesta (fex_aj) que conserva el total del FEX.
#   5. Da el mismo Theil A que data/resultados/theil_resumen.csv.
#
# Si todo sale "OK", tienes exactamente los mismos datos con los que se
# calcularon los resultados y puedes correr 05_theil.R y 06_descriptiva.R.
# =============================================================================

library(here)

source(here("R", "config.R"))
source(here("R", "datos.R"))
source(here("R", "theil.R"))

huellas <- read.table(here("data", "checksums.txt"), col.names = c("md5", "archivo"))
# El Theil guardado lo produce 05_theil.R. Si todavía no existe (por ejemplo,
# si se borraron las salidas para correr todo desde cero), esa comparación se omite.
ruta_resumen <- here("data", "resultados", "theil_resumen.csv")
resumen <- if (file.exists(ruta_resumen)) read.csv(ruta_resumen) else NULL
if (is.null(resumen)) cat("Aviso: no existe data/resultados/theil_resumen.csv; no se compara el Theil A.\n")

llaves  <- c("MES", "DIRECTORIO", "SECUENCIA_P", "HOGAR", "ORDEN")
ok_todo <- TRUE

chequear <- function(condicion, texto) {
  cat(if (condicion) "  OK    " else "  FALLA ", texto, "\n")
  if (!condicion) ok_todo <<- FALSE
}

for (anio in anios) {

  cat("\n----", anio, "----\n")

  # 1. Archivo íntegro
  archivo <- ruta_procesada(anio)
  esperado <- huellas$md5[huellas$archivo == basename(archivo)]
  chequear(file.exists(archivo) && unname(tools::md5sum(archivo)) == esperado,
           paste("huella MD5 de", basename(archivo)))
  if (!file.exists(archivo)) next

  a    <- cargar_analitica(anio)
  traz <- read.csv(here("data", "intermedia", "etapa2_analitica", "reportes", paste0("trazabilidad_", anio, ".csv")))

  # 2. Sin duplicados
  chequear(!anyDuplicated(a[llaves]), "sin duplicados (MES + llaves de persona)")

  # 3. Conteos = reporte de trazabilidad
  chequear(nrow(a) == traz$filas[1], paste("ocupados:", nrow(a)))
  chequear(sum(a$en_poblacion) == traz$filas[traz$paso == "5. Dimensiones completas"],
           paste("en_poblacion:", sum(a$en_poblacion)))
  chequear(sum(a$en_poblacion & a$responde) == traz$filas[grepl("^6", traz$paso)],
           paste("entran al Theil (en_poblacion & responde):", sum(a$en_poblacion & a$responde)))

  # 4. El ajuste por no respuesta reparte el peso, no lo crea ni lo destruye
  p <- a[a$en_poblacion, ]
  chequear(abs(sum(p$fex_aj) - sum(p$FEX)) < 1e-6 * sum(p$FEX), "suma fex_aj = suma FEX")
  chequear(all(p$fex_aj[!p$responde] == 0), "no respondientes con fex_aj = 0")

  # 5. Theil total (estimador A) = resultado guardado
  if (anio %in% anios_theil && !is.null(resumen)) {
    d   <- a[a$en_poblacion & a$responde, ]
    T_A <- theil_A(d$ingreso, d$fex_aj)
    ref <- resumen$T[resumen$anio == anio & resumen$peso == "fex_aj" & resumen$dimension == "total"]
    chequear(abs(T_A - ref) < 1e-10, sprintf("Theil A = %.4f (guardado: %.4f)", T_A, ref))
  } else if (!anio %in% anios_theil) {
    cat("  --    2020 excluido del Theil (ingreso faltante en la recolección telefónica)\n")
  }
}

cat("\n", if (ok_todo) "TODO CORRECTO: los datos están completos." else "HAY FALLAS: revisa los mensajes de arriba.", "\n")
if (!ok_todo) stop("La verificación de datos falló.")
