# =============================================================================
# 01 — Extraer las crudas anuales desde los microdatos del DANE
#
# NO hace parte de la replicación normal: las crudas ya están en data/raw/.
# Solo se corre para regenerarlas desde los .dta originales (ver README).
#
# Qué hace, para cada año 2018–2026:
#   1. Lee las columnas necesarias de tres módulos: Ocupados, Características
#      generales y Datos del hogar y la vivienda.
#   2. En 2018, 2019 y 2021 apila Cabecera + Resto (Área ya está dentro de
#      Cabecera, por eso se descarta).
#   3. Une los tres módulos con las llaves, mes por mes, con Ocupados como base.
#   4. Apila los meses 1 a 6 y guarda data/raw/geih_cruda_<año>.csv.gz.
#
# No filtra a nadie: la cruda tiene a todos los ocupados de enero a junio.
# Las variables que cambian de nombre entre marcos se guardan con un nombre
# común (SEXO, EDUC, FEX, TAM_EMPRESA) y el nombre original en <VAR>_FUENTE.
# =============================================================================

library(dplyr)
library(haven)

source("scripts/00_funciones.R")   # escribir_csv_gz()


# Carpeta con los .dta originales del DANE (SOLO LECTURA) ----
# Una subcarpeta por mes: AAAAMM/ (por ejemplo 201801/), con los nombres
# originales de los archivos. Cambiar esta ruta en cada computador.

carpeta_dta <- "C:/Users/GABRIEL/Documents/universidad/4 semestre/estadistica/statistics-geih/data/raw"


# Parámetros ----

anios <- 2018:2026
meses <- 1:6
anios_nacionales <- c(2020, 2022:2026)   # un solo archivo nacional (sin Área/Cabecera/Resto)

# Ocupados por año (columna "Ocupados" de la Tabla 2 de la primera entrega)
ocupados_tabla2 <- c("2018" = 174668, "2019" = 168441, "2020" = 146862,
                     "2021" = 146094, "2022" = 194647, "2023" = 183136,
                     "2024" = 178204, "2025" = 176176, "2026" = 177195)

llaves_persona <- c("DIRECTORIO", "SECUENCIA_P", "HOGAR", "ORDEN")
llaves_hogar   <- c("DIRECTORIO", "SECUENCIA_P", "HOGAR")


# Módulos ----
# Ocupados va primero: define las filas (los ocupados).
# relacion: cómo se une con Ocupados; dplyr se detiene si no se cumple.
# 2020 no tiene el módulo de vivienda: la recolección telefónica no preguntó el estrato.

modulos <- list(
  ocupados       = list(patron = "Ocupados",            id = llaves_persona, relacion = NA),
  car_gen        = list(patron = "Caracter.*generales", id = llaves_persona, relacion = "one-to-one"),
  hogar_vivienda = list(patron = ".*vivienda",          id = llaves_hogar,   relacion = "many-to-one")
)

modulos_excluidos <- list(hogar_vivienda = 2020)


# Variables ----
# cand:        nombres posibles (en mayúscula), en orden de prioridad.
# fuente:      guarda el nombre original en <VAR>_FUENTE (cambia entre marcos).
# requiere:    módulo del que depende (si falta ese año, queda en NA).

variables <- list(
  FEX         = list(cand = c("^FEX_C_?18$", "^FEX_C_?2011$", "^FEX_C$"), fuente = TRUE),  # FEX_C: 2020
  DPTO        = list(cand = "^DPTO$"),
  CLASE       = list(cand = "^CLASE$"),
  INGLABO     = list(cand = "^INGLABO$"),
  P6430       = list(cand = "^P6430$"),                    # posición ocupacional
  P6920       = list(cand = "^P6920$"),                    # cotiza a pensión
  P6040       = list(cand = "^P6040$"),                    # edad
  P6800       = list(cand = "^P6800$"),                    # horas semanales
  SEXO        = list(cand = c("^P3271$", "^P6020$")),      # marco 2018 / marco antiguo (mismos códigos)
  EDUC        = list(cand = c("^P3042$", "^P6210$"), fuente = TRUE),
  ESTRATO     = list(cand = "^P4030S1A1$", requiere = "hogar_vivienda"),
  TAM_EMPRESA = list(cand = c("^P3069$", "^P6870$"), fuente = TRUE)
)

vars_fuente <- names(variables)[sapply(variables, function(x) isTRUE(x$fuente))]


# =============================================================================
# FUNCIONES
# =============================================================================

# Un solo archivo por patrón (si hay 0 o varios, se detiene) ----
buscar_archivo <- function(ruta_mes, patron) {
  f <- list.files(ruta_mes, pattern = patron, full.names = TRUE, ignore.case = TRUE)
  if (length(f) != 1) stop("En ", ruta_mes, " hay ", length(f), " archivos con el patrón ", patron)
  f
}

contar_duplicados <- function(base, id_vars) {
  sum(duplicated(base[id_vars]))
}

# Llaves a texto (evita que 100000 se escriba como 1e+05) ----
a_texto <- function(x) {
  if (is.numeric(x)) format(x, scientific = FALSE, trim = TRUE) else trimws(as.character(x))
}

# Qué columna del archivo corresponde a cada variable ----
mapear_variables <- function(columnas) {
  col_may <- toupper(columnas)
  mapa <- list()
  for (v in names(variables)) {
    for (p in variables[[v]]$cand) {
      hit <- columnas[grepl(p, col_may)]
      if (length(hit) > 1) stop("La variable ", v, " coincide con varias columnas.")
      if (length(hit) == 1) { mapa[[v]] <- data.frame(final = v, original = hit); break }
    }
  }
  bind_rows(mapa)
}

# Leer un archivo de un módulo: solo llaves y variables, con nombres comunes ----
leer_modulo <- function(archivo, modulo) {
  id_vars  <- modulos[[modulo]]$id
  columnas <- names(read_dta(archivo, n_max = 0))      # solo los nombres
  col_id   <- columnas[toupper(columnas) %in% id_vars]
  if (length(col_id) != length(id_vars)) stop("Faltan llaves en ", basename(archivo))

  mapa <- mapear_variables(columnas)
  base <- read_dta(archivo, col_select = all_of(c(col_id, mapa$original))) %>%
    zap_labels() %>%
    zap_formats()

  names(base)[match(col_id, names(base))]        <- toupper(col_id)
  names(base)[match(mapa$original, names(base))] <- mapa$final

  if (anyNA(base[id_vars])) stop("Llaves faltantes en ", basename(archivo))

  base <- base %>%
    mutate(across(all_of(id_vars), a_texto),
           across(all_of(mapa$final), as.numeric))

  for (i in seq_len(nrow(mapa))) {
    if (mapa$final[i] %in% vars_fuente) base[[paste0(mapa$final[i], "_FUENTE")]] <- toupper(mapa$original[i])
  }
  base
}

# Un módulo en un mes ----
crear_modulo_mensual <- function(modulo, anio, mes) {
  cfg      <- modulos[[modulo]]
  ruta_mes <- file.path(carpeta_dta, paste0(anio, sprintf("%02d", mes)))

  if (anio %in% anios_nacionales) {
    base <- leer_modulo(buscar_archivo(ruta_mes, paste0("^", cfg$patron, ".*\\.dta$")), modulo)
  } else {
    # "^.{1,2}rea - " acepta "Area" y "Área"
    area     <- leer_modulo(buscar_archivo(ruta_mes, paste0("^.{1,2}rea - ", cfg$patron, ".*\\.dta$")), modulo)
    cabecera <- leer_modulo(buscar_archivo(ruta_mes, paste0("^Cabecera - ",  cfg$patron, ".*\\.dta$")), modulo)
    resto    <- leer_modulo(buscar_archivo(ruta_mes, paste0("^Resto - ",     cfg$patron, ".*\\.dta$")), modulo)

    # Área debe estar contenida en Cabecera; por eso no se apila
    fuera <- nrow(anti_join(area, cabecera, by = cfg$id))
    if (fuera > 0) stop(fuera, " registros de Área no están en Cabecera (", modulo, " ", anio, "-", mes, ")")

    base <- bind_rows(cabecera, resto)
  }

  if (contar_duplicados(base, cfg$id) > 0) stop("Duplicados en ", modulo, " ", anio, "-", mes)
  base %>% mutate(ANIO = anio, MES = mes)
}

# Unir un módulo a Ocupados verificando ----
# Las filas no pueden cambiar; FEX y DPTO deben coincidir entre módulos
# (el FEX de vivienda es del hogar, por eso solo se compara en car_gen).
unir_verificando <- function(principal, secundaria, modulo) {
  cfg <- modulos[[modulo]]
  sec <- secundaria %>% select(-ANIO, -MES) %>% mutate(.EN_MODULO = TRUE)
  comunes <- setdiff(intersect(names(principal), names(sec)), cfg$id)

  unida <- left_join(principal, sec, by = cfg$id, suffix = c("", ".otro"),
                     relationship = cfg$relacion)

  if (nrow(unida) != nrow(principal))  stop("La unión con ", modulo, " cambió las filas.")
  if (anyNA(unida$.EN_MODULO))         stop("Hay ocupados sin pareja en ", modulo)

  for (v in comunes) {
    a <- unida[[v]]; b <- unida[[paste0(v, ".otro")]]
    ambos <- !is.na(a) & !is.na(b)
    estricta <- v == "DPTO" || (v == "FEX" && modulo != "hogar_vivienda")
    if (estricta && is.numeric(a) && any(abs(a[ambos] - b[ambos]) > 1e-6 * pmax(1, abs(a[ambos])))) {
      stop(v, " no coincide entre Ocupados y ", modulo)
    }
    unida[[v]] <- coalesce(a, b)          # si falta en Ocupados, se completa
    unida[[paste0(v, ".otro")]] <- NULL
  }
  unida$.EN_MODULO <- NULL
  unida
}

# Un mes con los tres módulos unidos ----
unir_modulos_mes <- function(anio, mes) {
  incluidos <- names(modulos)[!sapply(names(modulos), function(m) anio %in% modulos_excluidos[[m]])]
  base <- crear_modulo_mensual("ocupados", anio, mes)
  for (m in incluidos[-1]) base <- unir_verificando(base, crear_modulo_mensual(m, anio, mes), m)

  # Variables que no existen ese año (estrato en 2020) quedan en NA
  for (v in names(variables)) if (!v %in% names(base)) base[[v]] <- NA_real_
  for (v in vars_fuente) if (!paste0(v, "_FUENTE") %in% names(base)) base[[paste0(v, "_FUENTE")]] <- NA_character_

  base %>%
    select(ANIO, MES, all_of(llaves_persona), FEX, FEX_FUENTE, DPTO, CLASE, INGLABO,
           P6430, P6920, P6040, P6800, SEXO, EDUC, EDUC_FUENTE, ESTRATO,
           TAM_EMPRESA, TAM_EMPRESA_FUENTE)
}


# =============================================================================
# CONSTRUCCIÓN
# =============================================================================

dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)

for (anio in anios) {

  base <- bind_rows(lapply(meses, function(m) unir_modulos_mes(anio, m)))

  # Verificaciones: sin personas repetidas y mismos ocupados que la Tabla 2
  stopifnot(
    "Hay personas repetidas (MES + llaves)" = contar_duplicados(base, c("MES", llaves_persona)) == 0,
    "El número de ocupados no coincide con la Tabla 2" = nrow(base) == ocupados_tabla2[[as.character(anio)]]
  )

  escribir_csv_gz(base, paste0("data/raw/geih_cruda_", anio, ".csv.gz"))
  cat(anio, "| ocupados:", nrow(base), "| meses:", paste(sort(unique(base$MES)), collapse = ","), "\n")
}
