# =============================================================================
# ETAPA 2 — Base analítica anual GEIH (una base por año)
#
# Parte de las bases crudas de la etapa 1 (data/final/base_<año>.rds) y:
#   1. Construye las variables armonizadas entre marcos (tablas de equivalencias).
#   2. Marca la población de estudio con indicadores. No borra ninguna fila.
#   3. Ajusta el factor de expansión por no respuesta de INGLABO (celdas).
#   4. Guarda la base analítica y reportes de trazabilidad y del ajuste.
#
# Principio: marcar, no borrar. El filtro se aplica al momento de analizar:
#   base %>% filter(en_poblacion)   y   pesos = fex_aj
# =============================================================================


# Librerías ----

library(here)
library(dplyr)


# Parámetros ----

anios <- 2018:2026

edad_min       <- 15    # el marco 2018 define ocupados desde 15 años; se aplica a todos
min_resp_celda <- 30    # mínimo de respondientes por celda en el ajuste de pesos

dir.create(here("data", "analitica", "reportes"), showWarnings = FALSE, recursive = TRUE)


# Cobertura geográfica común ----
# Los 24 departamentos presentes en 201801 (marco antiguo). Los 9 departamentos
# que agrega el marco 2018 (81, 85, 86, 88, 91, 94, 95, 97, 99) quedan fuera de
# la serie comparable y solo entran en el análisis con cobertura nacional.

deptos_comunes <- c(5, 8, 11, 13, 15, 17, 18, 19, 20, 23, 25, 27,
                    41, 44, 47, 50, 52, 54, 63, 66, 68, 70, 73, 76)


# Dimensiones de la descomposición por año ----
# 2020: sin estrato (la recolección telefónica no incluyó el módulo de vivienda).

dims_base <- c("educ", "formal", "sexo", "region", "estrato")

dims_anio <- function(anio) {
  if (anio == 2020) setdiff(dims_base, "estrato") else dims_base
}


# Niveles de ajuste de pesos ----
# Se intenta primero la celda más fina; si tiene menos de min_resp_celda
# respondientes, esas filas pasan al siguiente nivel, más grueso.
# La formalidad se incluye en todos los niveles: es la variable observada
# que mejor separa a quienes responden de quienes no, y es una dimensión
# de la descomposición.

niveles_ajuste <- list(
  c("posicion", "formal", "educ", "region", "sexo"),
  c("posicion", "formal", "educ", "region"),
  c("posicion", "formal", "educ"),
  c("posicion", "formal"),
  c("posicion")
)


# =============================================================================
# TABLAS DE EQUIVALENCIAS
# =============================================================================
# Los códigos que no aparecen en una tabla quedan en NA (p. ej. "no sabe").
# El reporte de códigos sin equivalencia permite revisar que no se pierda
# ningún código válido.


# Educación ----
# Escala común = la del marco antiguo, que es la más gruesa.
# PENDIENTE: confirmar con las etiquetas de P6210 que 9 = "no sabe".

niveles_educ <- c("Ninguno/preescolar", "Primaria", "Secundaria", "Media", "Superior")

eq_educ <- tribble(
  ~EDUC_FUENTE, ~EDUC, ~educ,
  # Marco antiguo
  "P6210",  1, "Ninguno/preescolar",
  "P6210",  2, "Ninguno/preescolar",
  "P6210",  3, "Primaria",
  "P6210",  4, "Secundaria",
  "P6210",  5, "Media",
  "P6210",  6, "Superior",
  # Marco 2018
  "P3042",  1, "Ninguno/preescolar",
  "P3042",  2, "Ninguno/preescolar",
  "P3042",  3, "Primaria",
  "P3042",  4, "Secundaria",
  "P3042",  5, "Media",          # media académica
  "P3042",  6, "Media",          # media técnica
  "P3042",  7, "Media",          # normalista
  "P3042",  8, "Superior",       # técnica profesional
  "P3042",  9, "Superior",       # tecnológica
  "P3042", 10, "Superior",       # universitaria
  "P3042", 11, "Superior",       # especialización
  "P3042", 12, "Superior",       # maestría
  "P3042", 13, "Superior"        # doctorado
)


# Tamaño de la empresa ----
# P3069 divide en dos la categoría superior de P6870; se agrupa en rangos
# que existen en ambos marcos.
# PENDIENTE: confirmar los rangos de P6870 con sus etiquetas.

niveles_tam <- c("Trabaja solo", "2 a 5", "6 a 10", "11 a 50", "51 o más")

eq_tam <- tribble(
  ~TAM_EMPRESA_FUENTE, ~TAM_EMPRESA, ~tam_empresa,
  "P6870", 1, "Trabaja solo",
  "P6870", 2, "2 a 5",
  "P6870", 3, "2 a 5",
  "P6870", 4, "6 a 10",
  "P6870", 5, "11 a 50",
  "P6870", 6, "11 a 50",
  "P6870", 7, "11 a 50",
  "P6870", 8, "51 o más",
  "P6870", 9, "51 o más",
  "P3069", 1, "Trabaja solo",
  "P3069", 2, "2 a 5",
  "P3069", 3, "2 a 5",
  "P3069", 4, "6 a 10",
  "P3069", 5, "11 a 50",
  "P3069", 6, "11 a 50",
  "P3069", 7, "11 a 50",
  "P3069", 8, "51 o más",
  "P3069", 9, "51 o más",
  "P3069", 10, "51 o más"
)


# Región ----
# Agrupación regional estilo DANE. Verifica que coincida con la definición
# que cites en el informe.

niveles_region <- c("Bogotá", "Caribe", "Oriental", "Central", "Pacífica", "Orinoquía-Amazonía")

eq_region <- bind_rows(
  tibble(DPTO = 11,                                 region = "Bogotá"),
  tibble(DPTO = c(8, 13, 20, 23, 44, 47, 70, 88),   region = "Caribe"),
  tibble(DPTO = c(15, 25, 50, 54, 68),              region = "Oriental"),
  tibble(DPTO = c(5, 17, 18, 41, 63, 66, 73),       region = "Central"),
  tibble(DPTO = c(19, 27, 52, 76),                  region = "Pacífica"),
  tibble(DPTO = c(81, 85, 86, 91, 94, 95, 97, 99),  region = "Orinoquía-Amazonía")
)


# =============================================================================
# FUNCIONES
# =============================================================================


# Unir una tabla de equivalencias y reportar códigos sin equivalencia ----

aplicar_equivalencia <- function(base, tabla, llaves, nueva, anio) {
  
  n_antes <- nrow(base)
  
  base <- left_join(base, tabla, by = llaves, relationship = "many-to-one")
  
  if (nrow(base) != n_antes) stop("La equivalencia de ", nueva, " cambió las filas en ", anio)
  
  # Códigos presentes en los datos que no tienen equivalencia
  codigo <- llaves[length(llaves)]
  
  sin_eq <- base %>%
    filter(!is.na(.data[[codigo]]), is.na(.data[[nueva]])) %>%
    count(across(all_of(llaves)), name = "n")
  
  if (nrow(sin_eq) > 0) {
    cat("\n", nueva, " | códigos sin equivalencia (quedan en NA):\n", sep = "")
    print(as.data.frame(sin_eq), row.names = FALSE)
  }
  
  base
}


# Ajuste de pesos por no respuesta ----
# Dentro de cada celda:  fex_aj = FEX * (suma FEX de todos) / (suma FEX de respondientes)
# Los no respondientes quedan con peso 0 y las filas fuera de la población con NA.
# Se conserva el total del FEX de cada celda.

ajustar_pesos <- function(base, en_pob) {
  
  d <- base %>%
    mutate(.fila = row_number()) %>%
    filter(en_pob)
  
  d$.celda <- NA_character_
  
  
  # Asignar cada fila a la celda más fina con suficientes respondientes ----
  
  for (k in seq_along(niveles_ajuste)) {
    
    libres <- is.na(d$.celda)
    if (!any(libres)) break
    
    vars  <- niveles_ajuste[[k]]
    clave <- do.call(paste, c(lapply(vars, function(v) as.character(d[[v]])), sep = " | "))
    
    n_resp <- tapply(d$responde[libres], clave[libres], sum)
    ok     <- libres & (n_resp[clave] >= min_resp_celda) %in% TRUE
    
    d$.celda[ok] <- paste0("N", k, " | ", clave[ok])
  }
  
  d$.celda[is.na(d$.celda)] <- paste0("N", length(niveles_ajuste) + 1, " | resto")
  
  
  # Factor de ajuste ----
  
  d <- d %>%
    group_by(.celda) %>%
    mutate(
      .fex_tot  = sum(FEX),
      .fex_resp = sum(FEX[responde]),
      .n_resp   = sum(responde)
    ) %>%
    ungroup()
  
  if (any(d$.n_resp == 0)) {
    stop("Hay una celda sin respondientes: ", paste(unique(d$.celda[d$.n_resp == 0]), collapse = ", "))
  }
  
  d <- d %>%
    mutate(
      .factor = .fex_tot / .fex_resp,
      .fex_aj = if_else(responde, FEX * .factor, 0)
    )
  
  
  # Verificación: el total del FEX se conserva ----
  
  if (abs(sum(d$.fex_aj) - sum(d$FEX)) > 1e-8 * sum(d$FEX)) {
    stop("El ajuste de pesos no conserva el total del FEX.")
  }
  
  
  # Resultados ----
  
  fex_aj <- rep(NA_real_, nrow(base))
  celda  <- rep(NA_character_, nrow(base))
  
  fex_aj[d$.fila] <- d$.fex_aj
  celda[d$.fila]  <- d$.celda
  
  resumen <- d %>%
    group_by(celda = .celda) %>%
    summarise(
      nivel     = substr(first(.celda), 1, 2),
      n         = n(),
      n_resp    = sum(responde),
      pct_resp  = round(100 * mean(responde), 1),
      factor    = round(first(.factor), 3),
      .groups   = "drop"
    )
  
  list(fex_aj = fex_aj, celda = celda, resumen = resumen)
}


# Participación de cada grupo antes y después del ajuste ----
# Diagnóstico: en las dimensiones usadas en las celdas debería cambiar poco;
# en las demás (formal, estrato) muestra el efecto real del ajuste.

comparar_participacion <- function(base, en_pob, pesos, dims) {
  
  d <- base[en_pob, ]
  d$.aj <- pesos[en_pob]
  
  bind_rows(lapply(dims, function(v) {
    d %>%
      filter(!is.na(.data[[v]])) %>%
      group_by(grupo = as.character(.data[[v]])) %>%
      summarise(fex = sum(FEX), aj = sum(.aj), .groups = "drop") %>%
      mutate(
        dimension     = v,
        pct_original  = round(100 * fex / sum(fex), 2),
        pct_ajustado  = round(100 * aj / sum(aj), 2),
        diferencia_pp = pct_ajustado - pct_original
      ) %>%
      select(dimension, grupo, pct_original, pct_ajustado, diferencia_pp)
  }))
}


# =============================================================================
# CONSTRUCCIÓN DE LA BASE ANALÍTICA DE UN AÑO
# =============================================================================

construir_analitica <- function(anio) {
  
  cat("\n=============================== ", anio, " ===============================\n")
  
  base <- readRDS(here("data", "final", paste0("base_", anio, ".rds")))
  dims <- dims_anio(anio)
  
  
  # 1. Variables armonizadas ----
  
  base <- base %>%
    aplicar_equivalencia(eq_educ,   c("EDUC_FUENTE", "EDUC"),               "educ",         anio) %>%
    aplicar_equivalencia(eq_tam,    c("TAM_EMPRESA_FUENTE", "TAM_EMPRESA"), "tam_empresa",  anio) %>%
    aplicar_equivalencia(eq_region, "DPTO",                                 "region",       anio) %>%
    mutate(
      
      # Cuantitativas
      ingreso = INGLABO,     # ingreso laboral mensual (pesos corrientes)
      edad    = P6040,
      horas   = P6800,       # horas semanales en el empleo principal
      
      # Cualitativas
      sexo = factor(
        case_when(SEXO == 1 ~ "Hombre", SEXO == 2 ~ "Mujer"),
        levels = c("Hombre", "Mujer")
      ),
      
      educ        = factor(educ,        levels = niveles_educ,   ordered = TRUE),
      tam_empresa = factor(tam_empresa, levels = niveles_tam,    ordered = TRUE),
      region      = factor(region,      levels = niveles_region),
      
      estrato = factor(
        if_else(ESTRATO %in% 1:6, ESTRATO, NA_real_),   # 0 y 9 son códigos especiales
        levels = 1:6, ordered = TRUE
      ),
      
      # Jornalero (8) se une a empleado particular: el marco 2018 casi no lo usa.
      # "Otro" (9) se une a cuenta propia por su tamaño mínimo.
      posicion = factor(
        case_when(
          P6430 %in% c(1, 8) ~ "Asalariado privado",
          P6430 == 2         ~ "Gobierno",
          P6430 == 3         ~ "Doméstico",
          P6430 %in% c(4, 9) ~ "Cuenta propia",
          P6430 == 5         ~ "Patrón",
          P6430 %in% c(6, 7) ~ "Sin remuneración"
        ),
        levels = c("Asalariado privado", "Gobierno", "Doméstico",
                   "Cuenta propia", "Patrón", "Sin remuneración")
      ),
      
      # PROPUESTA DE REGLA: formal = cotiza a pensión o ya es pensionado.
      formal = factor(
        case_when(P6920 %in% c(1, 3) ~ "Formal", P6920 == 2 ~ "Informal"),
        levels = c("Formal", "Informal")
      )
    )
  
  
  # 2. Indicadores de población ----
  # Cada f_* es una condición. en_poblacion las combina.
  
  base <- base %>%
    mutate(
      f_edad       = edad >= edad_min & !is.na(edad),
      f_remunerado = posicion != "Sin remuneración" & !is.na(posicion),
      f_cobertura  = DPTO %in% deptos_comunes,
      f_no_cero    = is.na(ingreso) | ingreso > 0,     # ingreso 0: fuera de la población
      f_dims       = if_all(all_of(c(dims, "posicion")), ~ !is.na(.x)),
      
      responde     = !is.na(ingreso) & ingreso > 0,
      
      en_poblacion     = f_edad & f_remunerado & f_cobertura & f_no_cero & f_dims,
      en_poblacion_nac = f_edad & f_remunerado &               f_no_cero & f_dims
    )
  
  
  # 3. Ajuste de pesos por no respuesta ----
  # fex_aj:     serie comparable (cobertura común)
  # fex_aj_nac: cobertura nacional completa (útil para 2022 en adelante)
  
  aj     <- ajustar_pesos(base, base$en_poblacion)
  aj_nac <- ajustar_pesos(base, base$en_poblacion_nac)
  
  base$fex_aj     <- aj$fex_aj
  base$celda_aj   <- aj$celda
  base$fex_aj_nac <- aj_nac$fex_aj
  
  
  # 4. Tabla de trazabilidad ----
  # Condiciones acumuladas: cada fila del reporte aplica todas las anteriores.
  
  pasos <- list(
    "0. Ocupados (base cruda)"               = rep(TRUE, nrow(base)),
    "1. Edad >= 15"                          = base$f_edad,
    "2. Remunerados"                         = base$f_remunerado,
    "3. Cobertura común (24 dptos.)"         = base$f_cobertura,
    "4. Sin ingreso igual a 0"               = base$f_no_cero,
    "5. Dimensiones completas"               = base$f_dims,
    "6. Responden ingreso (entran al Theil)" = base$responde
  )
  
  acumulado   <- rep(TRUE, nrow(base))
  fex_total   <- sum(base$FEX)
  trazabilidad <- list()
  
  for (p in names(pasos)) {
    acumulado <- acumulado & pasos[[p]]
    trazabilidad[[p]] <- data.frame(
      anio      = anio,
      paso      = p,
      filas     = sum(acumulado),
      pct_filas = round(100 * sum(acumulado) / nrow(base), 2),
      pct_fex   = round(100 * sum(base$FEX[acumulado]) / fex_total, 2)
    )
  }
  
  trazabilidad <- bind_rows(trazabilidad)
  
  
  # 5. Diagnóstico del ajuste ----
  
  participacion <- comparar_participacion(
    base, base$en_poblacion, base$fex_aj,
    c("posicion", dims)
  )
  
  
  # 6. Selección final de columnas ----
  
  base <- base %>%
    select(
      ANIO, MES, DIRECTORIO, SECUENCIA_P, HOGAR, ORDEN,
      FEX, fex_aj, fex_aj_nac, celda_aj,
      ingreso, edad, horas,
      sexo, educ, formal, region, estrato, posicion, tam_empresa,
      DPTO, CLASE,
      starts_with("f_"), responde, en_poblacion, en_poblacion_nac
    )
  
  
  # 7. Guardar ----
  
  ruta_rep <- here("data", "analitica", "reportes")
  
  saveRDS(base, here("data", "analitica", paste0("analitica_", anio, ".rds")))
  write.csv(trazabilidad,  file.path(ruta_rep, paste0("trazabilidad_",  anio, ".csv")), row.names = FALSE)
  write.csv(aj$resumen,    file.path(ruta_rep, paste0("celdas_ajuste_", anio, ".csv")), row.names = FALSE)
  write.csv(participacion, file.path(ruta_rep, paste0("participacion_", anio, ".csv")), row.names = FALSE)
  
  
  # 8. Resumen en consola ----
  
  cat("\nTrazabilidad:\n")
  print(trazabilidad[, -1], row.names = FALSE)
  
  cat("\nAjuste de pesos (cobertura común):\n")
  cat("  Celdas por nivel:\n"); print(table(aj$resumen$nivel))
  cat("  Factor de ajuste: mín", min(aj$resumen$factor),
      "| mediana", median(aj$resumen$factor),
      "| máx", max(aj$resumen$factor), "\n")
  
  cat("\nMayores cambios de participación por el ajuste (pp):\n")
  print(
    participacion %>% arrange(desc(abs(diferencia_pp))) %>% head(5),
    row.names = FALSE
  )
  
  invisible(NULL)
}


# =============================================================================
# DICCIONARIO DE VARIABLES ANALÍTICAS
# =============================================================================
# Tipo y escala de medición de cada variable, como pide la guía del proyecto.

diccionario <- tribble(
  ~variable,     ~tipo,                      ~escala,    ~descripcion,
  "ingreso",     "Cuantitativa continua",    "Razón",    "Ingreso laboral mensual (INGLABO), pesos corrientes",
  "edad",        "Cuantitativa discreta",    "Razón",    "Edad en años cumplidos (P6040)",
  "horas",       "Cuantitativa discreta",    "Razón",    "Horas semanales trabajadas en el empleo principal (P6800)",
  "sexo",        "Cualitativa",              "Nominal",  "Hombre / Mujer",
  "formal",      "Cualitativa",              "Nominal",  "Formal / Informal (cotización a pensión)",
  "region",      "Cualitativa",              "Nominal",  "Región según departamento",
  "posicion",    "Cualitativa",              "Nominal",  "Posición ocupacional agrupada (P6430)",
  "educ",        "Cualitativa",              "Ordinal",  "Máximo nivel educativo armonizado (5 niveles)",
  "estrato",     "Cualitativa",              "Ordinal",  "Estrato de la vivienda para tarifa de energía (1 a 6)",
  "tam_empresa", "Cualitativa",              "Ordinal",  "Tamaño de la empresa (5 rangos)"
)

write.csv(diccionario, here("data", "analitica", "diccionario_variables.csv"), row.names = FALSE)


# =============================================================================
# CONSTRUCCIÓN
# =============================================================================

# Prueba con un año de cada marco antes de correr todos:
# construir_analitica(2018)
# construir_analitica(2024)

for (anio in anios) {
  construir_analitica(anio)
}