# =============================================================================
# Lectura y escritura de las bases analíticas en CSV comprimido
#
# data/processed/geih_<año>.csv.gz es la base analítica de cada año (etapa 2)
# en un formato abierto y versionado en GitHub. Así cualquiera puede correr el
# Theil y la descriptiva sin descargar los 62 GB de microdatos del DANE.
#
# cargar_analitica() devuelve exactamente la misma base que
# data/intermedia/etapa2_analitica/analitica_<año>.rds (lo verifica tests/testthat/test-datos.R).
# =============================================================================


ruta_procesada <- function(anio) {
  here::here("data", "processed", paste0("geih_", anio, ".csv.gz"))
}


# Categorías de las variables cualitativas ----
# Deben coincidir con las de scripts/02_base_analitica.R. En un CSV los
# factores se guardan como texto; estas listas devuelven el orden original.

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

ordenadas <- c("educ", "estrato", "tam_empresa")   # cualitativas ordinales


# Tipo de cada columna al leer ----

tipos <- c(
  ANIO = "integer", MES = "integer",
  DIRECTORIO = "character", SECUENCIA_P = "character", HOGAR = "character", ORDEN = "character",
  FEX = "numeric", fex_aj = "numeric", fex_aj_nac = "numeric", celda_aj = "character",
  ingreso = "numeric", edad = "numeric", horas = "numeric",
  sexo = "character", educ = "character", formal = "character", region = "character",
  estrato = "character", posicion = "character", tam_empresa = "character",
  DPTO = "numeric", CLASE = "numeric",
  f_edad = "logical", f_remunerado = "logical", f_cobertura = "logical",
  f_no_cero = "logical", f_dims = "logical", responde = "logical",
  en_poblacion = "logical", en_poblacion_nac = "logical"
)


# Escribir ----
# Los números con decimales (los pesos) se escriben con 17 cifras para que, al
# leerlos, sean exactamente los mismos y el Theil no cambie ni en el último decimal.

exportar_analitica <- function(base, anio) {

  if (!identical(names(base), names(tipos))) stop("Las columnas no son las esperadas.")

  d <- as.data.frame(base)
  con_comillas <- which(sapply(d, function(x) is.character(x) || is.factor(x)))

  for (v in names(d)) {
    if (is.double(d[[v]])) d[[v]] <- sprintf("%.17g", d[[v]])
    if (is.factor(d[[v]])) d[[v]] <- as.character(d[[v]])
  }

  dir.create(dirname(ruta_procesada(anio)), showWarnings = FALSE, recursive = TRUE)
  con <- gzfile(ruta_procesada(anio), "w", encoding = "UTF-8")
  write.csv(d, con, row.names = FALSE, na = "NA", quote = con_comillas)
  close(con)

  invisible(ruta_procesada(anio))
}


# Leer ----

cargar_analitica <- function(anio) {

  ruta <- ruta_procesada(anio)
  if (!file.exists(ruta)) stop("No existe ", ruta, ". Revisa el README (sección Datos).")

  d <- read.csv(gzfile(ruta, encoding = "UTF-8"), colClasses = tipos,
                na.strings = "NA", encoding = "UTF-8")

  for (v in names(niveles)) {
    d[[v]] <- factor(d[[v]], levels = niveles[[v]], ordered = v %in% ordenadas)
  }

  dplyr::as_tibble(d)
}
