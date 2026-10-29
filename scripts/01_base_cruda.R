# =============================================================================
# ETAPA 1 — Base cruda anual GEIH (una base por año)
#
# Qué hace:
#   1. Lee solo las variables necesarias de Ocupados, Características
#      generales y Datos del hogar y vivienda (nombres flexibles).
#   2. Construye cada módulo por mes (Cabecera + Resto, o archivo nacional).
#   3. Une los módulos mes a mes, con Ocupados como base principal,
#      verificando filas, parejas, FEX y DPTO.
#   4. Apila los meses 1 a 6 y guarda un archivo por año + reportes.
#
# No recodifica nada: eso es la etapa 2 (base analítica).
# Requiere dplyr >= 1.1.0 (argumento `relationship` en los joins).
# =============================================================================


# Librerías ----

library(here)
library(dplyr)
library(haven)


# Parámetros ----
# anios, meses y anios_nacionales (años en un solo archivo nacional, sin
# Área/Cabecera/Resto) vienen de R/config.R.

source(here("R", "config.R"))

guardar_dta <- FALSE   # TRUE si además quieres una copia en .dta

dir.create(here("data", "final", "reportes"), showWarnings = FALSE, recursive = TRUE)


# Llaves ----

llaves_persona <- c("DIRECTORIO", "SECUENCIA_P", "HOGAR", "ORDEN")
llaves_hogar   <- c("DIRECTORIO", "SECUENCIA_P", "HOGAR")


# Módulos ----
# El orden importa: Ocupados va primero porque define las filas (la población
# del proyecto). Si una variable aparece en varios módulos, se conserva la de
# Ocupados y las otras copias se usan solo para verificar.
# relacion: tipo de unión esperada con Ocupados. dplyr detiene el código si
#           la llave no es única donde debería serlo.

modulos <- list(
  ocupados = list(
    patron   = "Ocupados",
    id       = llaves_persona,
    relacion = NA
  ),
  car_gen = list(
    patron   = "Caracter.*generales",
    id       = llaves_persona,
    relacion = "one-to-one"      # una fila por persona en ambos lados
  ),
  hogar_vivienda = list(
    patron   = ".*vivienda",
    id       = llaves_hogar,
    relacion = "many-to-one"     # varias personas comparten un hogar
  )
)

# Módulos que no se leen en ciertos años.
# 2020: la recolección telefónica no permite obtener el estrato.
modulos_excluidos <- list(
  hogar_vivienda = 2020
)


# Diccionario de variables ----
# Nombre final = nombre de la lista.
# cand:        patrones (regex) para buscar la columna, en orden de prioridad.
#              Se comparan contra el nombre en MAYÚSCULA, así que "fex_c_2011"
#              y "FEX_C_2011" son lo mismo. Los ^ y $ evitan capturar
#              variables parecidas (p. ej. P3042S1 cuando se busca P3042).
# obligatoria: si no se encuentra en ningún módulo, el código se detiene.
# fuente:      guarda en <VAR>_FUENTE el nombre original encontrado
#              (necesario cuando el nombre o los códigos cambian entre marcos).
# requiere:    módulo del que depende; si ese módulo se excluye en un año,
#              la variable queda en NA sin detener el código.

variables <- list(
  
  # Diseño muestral y geografía
  FEX     = list(cand = c("^FEX_C_?18$", "^FEX_C_?2011$", "^FEX_C$"), obligatoria = TRUE, fuente = TRUE),
  # FEX_C: nombre del factor en los meses telefónicos de 2020 (marzo-junio)
  DPTO    = list(cand = "^DPTO$",      obligatoria = TRUE),
  CLASE   = list(cand = "^CLASE$",     obligatoria = FALSE),
  AREA    = list(cand = "^AREA$",      obligatoria = FALSE),
  
  # Ingreso laboral
  INGLABO = list(cand = "^INGLABO$",   obligatoria = TRUE),
  P6500   = list(cand = "^P6500$",     obligatoria = FALSE),   # salario asalariados (respaldo)
  P6750   = list(cand = "^P6750$",     obligatoria = FALSE),   # ganancia independientes (respaldo)
  
  # Formalidad (la regla se define en la etapa 2)
  P6920   = list(cand = "^P6920$",     obligatoria = FALSE),   # cotiza a pensión
  P6430   = list(cand = "^P6430$",     obligatoria = FALSE),   # posición ocupacional
  TAM_EMPRESA = list(cand = c("^P3069$", "^P6870$"), obligatoria = FALSE, fuente = TRUE),
  # tamaño de la empresa: P3069 (marco 2018), P6870 (marco antiguo)
  
  # Variables cuantitativas para la descriptiva
  P6040   = list(cand = "^P6040$",     obligatoria = FALSE),   # edad
  P6800   = list(cand = "^P6800$",     obligatoria = FALSE),   # horas semanales
  
  # Dimensiones de la descomposición
  SEXO    = list(cand = c("^P3271$", "^P6020$"), obligatoria = TRUE, fuente = TRUE),
  EDUC    = list(cand = c("^P3042$", "^P6210$"), obligatoria = TRUE, fuente = TRUE),
  ESTRATO = list(cand = "^P4030S1A1$", obligatoria = TRUE, requiere = "hogar_vivienda")
)

vars_fuente <- names(variables)[sapply(variables, function(x) isTRUE(x$fuente))]


# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================


# Buscar archivo por patrón ----
# Se detiene si encuentra 0 archivos o más de 1

buscar_archivo <- function(ruta_mes, patron, periodo) {
  
  encontrado <- list.files(
    ruta_mes,
    pattern     = patron,
    full.names  = TRUE,
    ignore.case = TRUE
  )
  
  if (length(encontrado) != 1) {
    stop(
      "\nPara ", periodo, " se encontraron ", length(encontrado),
      " archivos con el patrón '", patron, "'.\n",
      "Coincidencias:\n", paste(basename(encontrado), collapse = "\n"), "\n",
      "Archivos en la carpeta:\n", paste(list.files(ruta_mes), collapse = "\n")
    )
  }
  
  encontrado
}


# Contar duplicados ----

contar_duplicados <- function(base, id_vars) {
  base %>%
    count(across(all_of(id_vars))) %>%
    filter(n > 1) %>%
    nrow()
}


# Llaves a texto ----
# Evita que 100000 se convierta en "1e+05" y que un mes traiga la llave
# como número y otro como texto.

a_texto <- function(x) {
  if (is.numeric(x)) {
    format(x, scientific = FALSE, trim = TRUE)
  } else {
    trimws(as.character(x))
  }
}


# Variables a número ----
# Si la columna viene como texto, la convierte y avisa si algún valor
# no vacío se perdió en la conversión (p. ej. "1.234,5").

a_numero <- function(x, nombre, archivo) {
  
  if (is.numeric(x)) return(as.numeric(x))
  
  txt <- trimws(as.character(x))
  txt[txt == ""] <- NA
  y   <- suppressWarnings(as.numeric(txt))
  
  perdidos <- is.na(y) & !is.na(txt)
  
  if (any(perdidos)) {
    warning(
      "En ", archivo, ", ", sum(perdidos), " valores de ", nombre,
      " no se pudieron convertir a número. Ejemplos: ",
      paste(head(unique(txt[perdidos]), 3), collapse = ", ")
    )
  }
  
  y
}


# Mapear variables ----
# Recibe los nombres de columnas de un archivo y devuelve qué columna
# original corresponde a cada variable final.
# 'otros' registra candidatos adicionales presentes (p. ej. si un archivo
# trae P6020 y P3271 a la vez), para revisarlos en el reporte.

mapear_variables <- function(columnas, archivo) {
  
  col_may <- toupper(columnas)
  mapa    <- list()
  
  for (v in names(variables)) {
    
    elegido <- NA_character_
    otros   <- character(0)
    
    for (p in variables[[v]]$cand) {
      
      hit <- columnas[grepl(p, col_may)]
      
      if (length(hit) > 1) {
        stop(
          "\nEn ", basename(archivo), " la variable ", v,
          " coincide con varias columnas: ", paste(hit, collapse = ", ")
        )
      }
      
      if (length(hit) == 1) {
        if (is.na(elegido)) elegido <- hit else otros <- c(otros, hit)
      }
    }
    
    if (!is.na(elegido)) {
      mapa[[v]] <- data.frame(
        final    = v,
        original = elegido,
        otros    = paste(otros, collapse = ", ")
      )
    }
  }
  
  if (length(mapa) == 0) {
    return(data.frame(final = character(), original = character(), otros = character()))
  }
  
  bind_rows(mapa)
}


# Leer un archivo de un módulo ----
# Lee solo llaves + variables del diccionario, armoniza nombres y tipos.

leer_modulo <- function(archivo, modulo) {
  
  id_vars  <- modulos[[modulo]]$id
  columnas <- names(read_dta(archivo, n_max = 0))   # solo nombres, sin datos
  
  
  # Llaves ----
  
  col_id <- columnas[toupper(columnas) %in% id_vars]
  faltan <- setdiff(id_vars, toupper(col_id))
  
  if (length(faltan) > 0) {
    stop("\nEn ", basename(archivo), " faltan las llaves: ", paste(faltan, collapse = ", "))
  }
  
  if (anyDuplicated(toupper(col_id)) > 0) {
    stop("\nEn ", basename(archivo), " hay llaves repetidas con distinta mayúscula.")
  }
  
  
  # Variables ----
  
  mapa <- mapear_variables(columnas, archivo)
  
  base <- read_dta(archivo, col_select = all_of(c(col_id, mapa$original))) %>%
    zap_labels() %>%
    zap_formats()
  
  names(base)[match(col_id, names(base))]        <- toupper(col_id)
  names(base)[match(mapa$original, names(base))] <- mapa$final
  
  
  # Tipos ----
  
  if (anyNA(base[id_vars])) {
    stop("\nEn ", basename(archivo), " hay llaves con valores faltantes.")
  }
  
  base <- base %>%
    mutate(
      across(all_of(id_vars), a_texto),
      across(all_of(mapa$final), ~ a_numero(.x, cur_column(), basename(archivo)))
    )
  
  
  # Nombre original de las variables que cambian entre marcos ----
  
  for (i in seq_len(nrow(mapa))) {
    v <- mapa$final[i]
    if (v %in% vars_fuente) {
      base[[paste0(v, "_FUENTE")]] <- toupper(mapa$original[i])
    }
  }
  
  list(base = base, mapa = mapa)
}


# =============================================================================
# BASE MENSUAL DE UN MÓDULO
# =============================================================================

crear_modulo_mensual <- function(modulo, anio, mes) {
  
  cfg      <- modulos[[modulo]]
  id_vars  <- cfg$id
  periodo  <- paste0(anio, sprintf("%02d", mes))
  ruta_mes <- here("data", "raw", periodo)
  
  
  # Años sin desagregación ----
  
  if (anio %in% anios_nacionales) {
    
    archivo <- buscar_archivo(ruta_mes, paste0("^", cfg$patron, ".*\\.dta$"), periodo)
    lectura <- leer_modulo(archivo, modulo)
    
    base <- lectura$base %>%
      mutate(ORIGEN = "nacional", ANIO = anio, MES = mes)
    
    mapa  <- lectura$mapa
    n_dup <- contar_duplicados(base, id_vars)
    
    cat("\n", modulo, " | ", periodo, " | nacional | ", nrow(base),
        " obs. | duplicados: ", n_dup, "\n", sep = "")
    
    if (n_dup > 0) stop("Hay duplicados en ", modulo, " para ", periodo)
    
  } else {
    
    
    # Años con desagregación ----
    # "^.{1,2}rea - " acepta "Area" y "Área"
    
    archivo_area     <- buscar_archivo(ruta_mes, paste0("^.{1,2}rea - ", cfg$patron, ".*\\.dta$"), periodo)
    archivo_cabecera <- buscar_archivo(ruta_mes, paste0("^Cabecera - ",  cfg$patron, ".*\\.dta$"), periodo)
    archivo_resto    <- buscar_archivo(ruta_mes, paste0("^Resto - ",     cfg$patron, ".*\\.dta$"), periodo)
    
    lec_area     <- leer_modulo(archivo_area,     modulo)
    lec_cabecera <- leer_modulo(archivo_cabecera, modulo)
    lec_resto    <- leer_modulo(archivo_resto,    modulo)
    
    base_area     <- lec_area$base     %>% mutate(ORIGEN = "area")
    base_cabecera <- lec_cabecera$base %>% mutate(ORIGEN = "cabecera")
    base_resto    <- lec_resto$base    %>% mutate(ORIGEN = "resto")
    
    
    # Cabecera y Resto deben traer las mismas variables ----
    # AREA se excluye: identifica áreas metropolitanas, así que solo existe
    # en Cabecera. En las filas de Resto queda en NA, y eso es correcto.
    
    vars_cab   <- setdiff(lec_cabecera$mapa$final, "AREA")
    vars_resto <- setdiff(lec_resto$mapa$final,    "AREA")
    
    if (!setequal(vars_cab, vars_resto)) {
      warning(
        "Cabecera y Resto no traen las mismas variables en ", modulo, " ", periodo, ".\n",
        "Solo en Cabecera: ", paste(setdiff(vars_cab, vars_resto), collapse = ", "), "\n",
        "Solo en Resto: ",    paste(setdiff(vars_resto, vars_cab), collapse = ", ")
      )
    }
    
    
    # Duplicados internos ----
    
    dup_area     <- contar_duplicados(base_area,     id_vars)
    dup_cabecera <- contar_duplicados(base_cabecera, id_vars)
    dup_resto    <- contar_duplicados(base_resto,    id_vars)
    
    
    # Solapamiento Área - Cabecera ----
    # Área debe estar contenida en Cabecera; por eso no se apila.
    
    solapamiento <- base_area %>%
      select(any_of(c(id_vars, "AREA"))) %>%
      inner_join(
        base_cabecera %>% select(any_of(c(id_vars, "AREA"))),
        by     = id_vars,
        suffix = c("_area", "_cabecera")
      )
    
    n_solapados  <- nrow(solapamiento)
    n_area_fuera <- nrow(base_area) - n_solapados
    
    if (all(c("AREA_area", "AREA_cabecera") %in% names(solapamiento))) {
      diferente_area <- sum(solapamiento$AREA_area != solapamiento$AREA_cabecera, na.rm = TRUE)
    } else {
      diferente_area <- NA
    }
    
    
    # Cabecera + Resto ----
    
    base  <- bind_rows(base_cabecera, base_resto) %>% mutate(ANIO = anio, MES = mes)
    mapa  <- lec_cabecera$mapa
    n_dup <- contar_duplicados(base, id_vars)
    
    cat("\n", modulo, " | ", periodo, " | desagregada",
        " | Área: ", nrow(base_area), " | Cabecera: ", nrow(base_cabecera),
        " | Resto: ", nrow(base_resto), " | Área fuera de Cabecera: ", n_area_fuera,
        " | Dif. AREA: ", diferente_area, " | Final: ", nrow(base),
        " | Duplicados: ", n_dup, "\n", sep = "")
    
    
    # Validaciones ----
    
    if (dup_area > 0)     warning("Duplicados internos en Área: ",     modulo, " ", periodo)
    if (dup_cabecera > 0) warning("Duplicados internos en Cabecera: ", modulo, " ", periodo)
    if (dup_resto > 0)    warning("Duplicados internos en Resto: ",    modulo, " ", periodo)
    
    if (n_area_fuera > 0) {
      warning(n_area_fuera, " registros de Área no están en Cabecera: ", modulo, " ", periodo)
    }
    
    if (isTRUE(diferente_area > 0)) {
      warning("Diferencias en AREA entre Área y Cabecera: ", modulo, " ", periodo)
    }
    
    if (n_dup > 0) stop("Duplicados en Cabecera + Resto: ", modulo, " ", periodo)
  }
  
  mapa <- mapa %>% mutate(ANIO = anio, MES = mes, modulo = modulo, .before = 1)
  
  list(base = base, mapa = mapa)
}


# =============================================================================
# UNIÓN VERIFICADA DE UN MÓDULO CON LA BASE PRINCIPAL
# =============================================================================
# Verificaciones:
#   - Las filas de la base principal no cambian.
#   - Cuántas personas no encuentran pareja en el módulo.
#   - Las variables que están en ambos módulos (FEX, DPTO, CLASE...) deben
#     coincidir. FEX y DPTO detienen el código; las demás solo avisan.
#     El FEX de hogar-vivienda solo avisa: es un registro de hogar, no de persona.

unir_verificando <- function(principal, secundaria, modulo, periodo) {
  
  cfg     <- modulos[[modulo]]
  id_vars <- cfg$id
  sufijo  <- paste0(".", modulo)
  n_antes <- nrow(principal)
  
  sec <- secundaria %>%
    select(-any_of(c("ORIGEN", "ANIO", "MES"))) %>%
    mutate(.EN_MODULO = TRUE)
  
  comunes <- setdiff(intersect(names(principal), names(sec)), id_vars)
  
  unida <- left_join(
    principal, sec,
    by           = id_vars,
    suffix       = c("", sufijo),
    relationship = cfg$relacion
  )
  
  
  # Filas ----
  
  if (nrow(unida) != n_antes) {
    stop("La unión con ", modulo, " cambió las filas en ", periodo,
         ": ", n_antes, " -> ", nrow(unida))
  }
  
  
  # Parejas ----
  
  sin_pareja <- sum(is.na(unida$.EN_MODULO))
  
  if (sin_pareja > 0) {
    warning(sin_pareja, " ocupados sin pareja en ", modulo, " (", periodo, ")")
  }
  
  
  # Variables repetidas entre módulos ----
  
  control <- list()
  
  for (v in comunes) {
    
    a <- unida[[v]]
    b <- unida[[paste0(v, sufijo)]]
    
    ambos <- !is.na(a) & !is.na(b)
    
    if (is.numeric(a) && is.numeric(b)) {
      difer <- ambos & abs(a - b) > 1e-6 * pmax(1, abs(a))   # tolerancia relativa
    } else {
      difer <- ambos & a != b
    }
    
    n_dif     <- sum(difer)
    n_relleno <- sum(is.na(a) & !is.na(b))
    
    estricta <- v == "DPTO" || (v == "FEX" && modulo != "hogar_vivienda")
    
    if (n_dif > 0) {
      
      msg <- paste0(n_dif, " diferencias en ", v, " entre ocupados y ", modulo, " (", periodo, ")")
      
      if (estricta) {
        print(head(unida[difer, c(id_vars, v, paste0(v, sufijo))], 5))
        stop(msg)
      } else {
        warning(msg)
      }
    }
    
    unida[[v]] <- coalesce(a, b)            # si falta en ocupados, se completa
    unida[[paste0(v, sufijo)]] <- NULL
    
    control[[v]] <- data.frame(
      periodo     = periodo,
      modulo      = modulo,
      variable    = v,
      diferencias = n_dif,
      rellenados  = n_relleno
    )
  }
  
  unida$.EN_MODULO <- NULL
  
  list(
    base    = unida,
    union   = data.frame(periodo = periodo, modulo = modulo, filas = n_antes, sin_pareja = sin_pareja),
    control = bind_rows(control)
  )
}


# =============================================================================
# BASE MENSUAL UNIDA
# =============================================================================

unir_modulos_mes <- function(anio, mes) {
  
  periodo <- paste0(anio, sprintf("%02d", mes))
  
  incluidos <- names(modulos)[
    !sapply(names(modulos), function(m) anio %in% modulos_excluidos[[m]])
  ]
  
  if (incluidos[1] != "ocupados") stop("Ocupados debe ser el primer módulo.")
  
  
  # Leer módulos ----
  
  leidos <- lapply(incluidos, function(m) crear_modulo_mensual(m, anio, mes))
  names(leidos) <- incluidos
  
  
  # Unir sobre Ocupados ----
  
  base      <- leidos$ocupados$base
  uniones   <- list()
  controles <- list()
  
  for (m in incluidos[-1]) {
    r <- unir_verificando(base, leidos[[m]]$base, m, periodo)
    base           <- r$base
    uniones[[m]]   <- r$union
    controles[[m]] <- r$control
  }
  
  
  # Variables no encontradas ----
  
  for (v in names(variables)) {
    
    if (!v %in% names(base)) {
      
      req      <- variables[[v]]$requiere
      excusada <- !is.null(req) && !(req %in% incluidos)
      
      if (isTRUE(variables[[v]]$obligatoria) && !excusada) {
        stop("\nLa variable obligatoria ", v, " no está en ningún módulo de ", periodo)
      }
      
      base[[v]] <- NA_real_
      if (v %in% vars_fuente) base[[paste0(v, "_FUENTE")]] <- NA_character_
    }
  }
  
  
  # Orden de columnas ----
  
  base <- base %>%
    select(all_of(c(
      "ANIO", "MES", "ORIGEN", llaves_persona,
      names(variables), paste0(vars_fuente, "_FUENTE")
    )))
  
  list(
    base      = base,
    mapa      = bind_rows(lapply(leidos, `[[`, "mapa")),
    uniones   = bind_rows(uniones),
    controles = bind_rows(controles)
  )
}


# =============================================================================
# BASE ANUAL
# =============================================================================

construir_anio <- function(anio) {
  
  cat("\n=============================== ", anio, " ===============================\n")
  
  res  <- lapply(meses, function(m) unir_modulos_mes(anio, m))
  base <- bind_rows(lapply(res, `[[`, "base"))
  
  
  # Duplicados en el año ----
  # Con MES: no debe haber ninguno.
  # Sin MES: diagnóstico. Una misma llave en dos meses es otra encuesta a la
  #          misma vivienda, no un error, pero conviene saber cuántas hay.
  
  dup_con_mes <- contar_duplicados(base, c("MES", llaves_persona))
  dup_sin_mes <- contar_duplicados(base, llaves_persona)
  
  if (dup_con_mes > 0) stop("Duplicados (MES + llaves) en ", anio)
  
  
  # Reportes ----
  
  rep_vars    <- bind_rows(lapply(res, `[[`, "mapa"))
  rep_union   <- bind_rows(lapply(res, `[[`, "uniones"))
  rep_control <- bind_rows(lapply(res, `[[`, "controles"))
  
  rep_na <- data.frame(
    variable = names(base),
    n_na     = colSums(is.na(base)),
    pct_na   = round(100 * colMeans(is.na(base)), 2),
    row.names = NULL
  )
  
  ruta_rep <- here("data", "final", "reportes")
  write.csv(rep_vars,    file.path(ruta_rep, paste0("variables_", anio, ".csv")), row.names = FALSE)
  write.csv(rep_union,   file.path(ruta_rep, paste0("uniones_",   anio, ".csv")), row.names = FALSE)
  write.csv(rep_control, file.path(ruta_rep, paste0("controles_", anio, ".csv")), row.names = FALSE)
  write.csv(rep_na,      file.path(ruta_rep, paste0("faltantes_", anio, ".csv")), row.names = FALSE)
  
  
  # Guardar ----
  
  saveRDS(base, here("data", "final", paste0("base_", anio, ".rds")))
  if (guardar_dta) write_dta(base, here("data", "final", paste0("base_", anio, ".dta")))
  
  
  # Resumen en consola ----
  
  cat("\n>>> ", anio, ": ", nrow(base), " ocupados guardados\n", sep = "")
  cat("Observaciones por mes:\n"); print(table(base$MES))
  cat("Llaves repetidas entre meses (diagnóstico):", dup_sin_mes, "\n")
  cat("Dónde se encontró cada variable:\n")
  print(distinct(rep_vars, final, modulo, original, otros) %>% arrange(final, modulo), row.names = FALSE)
  
  rm(base, res)
  gc()
  invisible(NULL)
}


# =============================================================================
# DIAGNÓSTICO: inventario de variables sin leer los datos
# =============================================================================
# Para un periodo, muestra por módulo qué variables del diccionario se
# encontraron y con qué nombre, y cuáles faltan. Además lista las columnas
# que contienen `buscar` (útil para encontrar el nombre real de una variable).
# En años desagregados revisa el archivo de Cabecera.
# No se ejecuta al correr el script; se llama a mano, por ejemplo:
#   inventario(2020, 1, buscar = "FEX|FACTOR|EXP")

inventario <- function(anio, mes, buscar = NULL) {
  
  periodo  <- paste0(anio, sprintf("%02d", mes))
  ruta_mes <- here("data", "raw", periodo)
  prefijo  <- if (anio %in% anios_nacionales) "^" else "^Cabecera - "
  
  for (m in names(modulos)) {
    
    if (anio %in% modulos_excluidos[[m]]) next
    
    archivo  <- buscar_archivo(ruta_mes, paste0(prefijo, modulos[[m]]$patron, ".*\\.dta$"), periodo)
    columnas <- names(read_dta(archivo, n_max = 0))
    mapa     <- mapear_variables(columnas, archivo)
    
    cat("\n---", m, "|", periodo, "|", basename(archivo), "---\n")
    cat("Encontradas:", paste0(mapa$final, "=", mapa$original, collapse = ", "), "\n")
    cat("No están:   ", paste(setdiff(names(variables), mapa$final), collapse = ", "), "\n")
    
    if (!is.null(buscar)) {
      hits <- grep(buscar, columnas, ignore.case = TRUE, value = TRUE)
      cat("Columnas con '", buscar, "': ", paste(hits, collapse = ", "), "\n", sep = "")
    }
  }
  
  invisible(NULL)
}


# =============================================================================
# CONSTRUCCIÓN DE BASES
# =============================================================================

for (anio in anios) {
  construir_anio(anio)
}