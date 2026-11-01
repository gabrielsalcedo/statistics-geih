# =============================================================================
# 02 — Bases finales: de data/raw a data/final
#
# Para cada año 2018–2026, a partir de la cruda (todos los ocupados, meses 1–6):
#   1. Armoniza las variables entre el marco antiguo (2018–2021) y el marco
#      2018 (2022–2026).
#   2. Marca la población de estudio con indicadores f_*. No borra a nadie.
#   3. Ajusta el factor de expansión por no respuesta de ingreso (fex_aj).
#   4. Guarda data/final/geih_<año>.csv.gz y la trazabilidad de la depuración
#      (Tabla 2 de la primera entrega) en outputs/trazabilidad.csv.
#
# Quienes entran al Theil: en_poblacion & responde, con peso fex_aj.
# =============================================================================

library(dplyr)

source("scripts/00_funciones.R")   # leer_cruda(), escribir_csv_gz()


# Parámetros (decisiones de la primera entrega) ----

anios          <- 2018:2026
edad_min       <- 15     # el marco 2018 define ocupados desde 15 años; se aplica a todos
min_resp_celda <- 30     # mínimo de respondientes por celda en el ajuste de pesos

# Cobertura común: los 24 departamentos que la encuesta cubre en todos los años.
# Los 9 que agrega el marco 2018 (81, 85, 86, 88, 91, 94, 95, 97, 99) quedan fuera.
deptos_comunes <- c(5, 8, 11, 13, 15, 17, 18, 19, 20, 23, 25, 27,
                    41, 44, 47, 50, 52, 54, 63, 66, 68, 70, 73, 76)

# Dimensiones de la descomposición. 2020 no tiene estrato (recolección telefónica).
dimensiones <- c("educ", "formal", "sexo", "region", "estrato")
dims_anio   <- function(anio) if (anio == 2020) setdiff(dimensiones, "estrato") else dimensiones

# Celdas del ajuste por no respuesta: primero la más fina; si tiene menos de
# min_resp_celda respondientes, esas personas pasan al nivel siguiente, más grueso.
niveles_ajuste <- list(
  c("posicion", "formal", "educ", "region", "sexo"),
  c("posicion", "formal", "educ", "region"),
  c("posicion", "formal", "educ"),
  c("posicion", "formal"),
  c("posicion")
)


# =============================================================================
# TABLAS DE EQUIVALENCIAS ENTRE MARCOS
# =============================================================================
# Los códigos que no aparecen quedan en NA (por ejemplo, 9 o 99 = "no sabe").

# Educación: escala común = la del marco antiguo (5 niveles) ----
eq_educ <- tribble(
  ~EDUC_FUENTE, ~EDUC, ~educ,
  "P6210",  1, "Ninguno/preescolar",
  "P6210",  2, "Ninguno/preescolar",
  "P6210",  3, "Primaria",
  "P6210",  4, "Secundaria",
  "P6210",  5, "Media",
  "P6210",  6, "Superior",
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

# Tamaño de la empresa: rangos que existen en los dos marcos ----
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

# Región según el departamento ----
eq_region <- bind_rows(
  tibble(DPTO = 11,                                 region = "Bogotá"),
  tibble(DPTO = c(8, 13, 20, 23, 44, 47, 70, 88),   region = "Caribe"),
  tibble(DPTO = c(15, 25, 50, 54, 68),              region = "Oriental"),
  tibble(DPTO = c(5, 17, 18, 41, 63, 66, 73),       region = "Central"),
  tibble(DPTO = c(19, 27, 52, 76),                  region = "Pacífica"),
  tibble(DPTO = c(81, 85, 86, 91, 94, 95, 97, 99),  region = "Orinoquía-Amazonía")
)


# =============================================================================
# AJUSTE DE PESOS POR NO RESPUESTA
# =============================================================================
# Dentro de cada celda: fex_aj = FEX × (suma FEX de todos) / (suma FEX de quienes responden).
# Quien no responde queda con peso 0; fuera de la población, NA.
# Así el peso de quienes no reportan ingreso se reparte entre quienes sí, y el
# total del FEX de cada celda se conserva.

ajustar_pesos <- function(base, en_pob) {

  d <- base %>% mutate(.fila = row_number()) %>% filter(en_pob)
  d$.celda <- NA_character_

  # Cada persona va a la celda más fina que tenga suficientes respondientes
  for (k in seq_along(niveles_ajuste)) {
    libres <- is.na(d$.celda)
    if (!any(libres)) break
    clave  <- do.call(paste, c(lapply(niveles_ajuste[[k]], function(v) as.character(d[[v]])), sep = " | "))
    n_resp <- tapply(d$responde[libres], clave[libres], sum)
    ok     <- libres & (n_resp[clave] >= min_resp_celda) %in% TRUE
    d$.celda[ok] <- paste0("N", k, " | ", clave[ok])
  }
  d$.celda[is.na(d$.celda)] <- paste0("N", length(niveles_ajuste) + 1, " | resto")

  # Factor de ajuste de cada celda
  d <- d %>%
    group_by(.celda) %>%
    mutate(.factor = sum(FEX) / sum(FEX[responde]), .n_resp = sum(responde)) %>%
    ungroup() %>%
    mutate(.fex_aj = if_else(responde, FEX * .factor, 0))

  if (any(d$.n_resp == 0)) stop("Hay una celda sin respondientes.")

  fex_aj <- rep(NA_real_, nrow(base));      fex_aj[d$.fila] <- d$.fex_aj
  celda  <- rep(NA_character_, nrow(base)); celda[d$.fila]  <- d$.celda
  list(fex_aj = fex_aj, celda = celda)
}


# =============================================================================
# BASE FINAL DE UN AÑO
# =============================================================================

dir.create("data/final", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs",    showWarnings = FALSE, recursive = TRUE)

trazabilidad <- list()

for (anio in anios) {

  base <- leer_cruda(anio)
  dims <- dims_anio(anio)


  # 1. Variables armonizadas ----

  n_antes <- nrow(base)
  base <- base %>%
    left_join(eq_educ,   by = c("EDUC_FUENTE", "EDUC"),               relationship = "many-to-one") %>%
    left_join(eq_tam,    by = c("TAM_EMPRESA_FUENTE", "TAM_EMPRESA"), relationship = "many-to-one") %>%
    left_join(eq_region, by = "DPTO",                                 relationship = "many-to-one")
  stopifnot("Las equivalencias cambiaron las filas" = nrow(base) == n_antes)

  base <- base %>%
    mutate(
      ingreso = INGLABO,     # ingreso laboral mensual (pesos corrientes)
      edad    = P6040,
      horas   = P6800,       # horas semanales en el empleo principal

      sexo        = factor(case_when(SEXO == 1 ~ "Hombre", SEXO == 2 ~ "Mujer"), levels = niveles$sexo),
      educ        = factor(educ,        levels = niveles$educ,        ordered = TRUE),
      tam_empresa = factor(tam_empresa, levels = niveles$tam_empresa, ordered = TRUE),
      region      = factor(region,      levels = niveles$region),
      estrato     = factor(if_else(ESTRATO %in% 1:6, ESTRATO, NA_real_),   # 0 y 9: sin estrato
                           levels = 1:6, ordered = TRUE),

      # Posición ocupacional (P6430). Jornalero (8) va con empleado particular;
      # "Otro" (9) con cuenta propia; 6 y 7 son trabajadores sin remuneración.
      # Ojo: desde 2022 el código 7 tiene ingreso (ver README, hallazgos).
      posicion = factor(
        case_when(
          P6430 %in% c(1, 8) ~ "Asalariado privado",
          P6430 == 2         ~ "Gobierno",
          P6430 == 3         ~ "Doméstico",
          P6430 %in% c(4, 9) ~ "Cuenta propia",
          P6430 == 5         ~ "Patrón",
          P6430 %in% c(6, 7) ~ "Sin remuneración"
        ),
        levels = niveles$posicion
      ),

      # Formal = cotiza a pensión o ya es pensionado (P6920 = 1 o 3)
      formal = factor(case_when(P6920 %in% c(1, 3) ~ "Formal", P6920 == 2 ~ "Informal"),
                      levels = niveles$formal)
    )


  # 2. Indicadores de población (marcar, no borrar) ----

  base <- base %>%
    mutate(
      f_edad       = edad >= edad_min & !is.na(edad),
      f_remunerado = posicion != "Sin remuneración" & !is.na(posicion),
      f_cobertura  = DPTO %in% deptos_comunes,
      f_no_cero    = is.na(ingreso) | ingreso > 0,     # ingreso 0: fuera de la población
      f_dims       = if_all(all_of(c(dims, "posicion")), ~ !is.na(.x)),
      responde     = !is.na(ingreso) & ingreso > 0,
      en_poblacion     = f_edad & f_remunerado & f_cobertura & f_no_cero & f_dims,
      en_poblacion_nac = f_edad & f_remunerado &               f_no_cero & f_dims   # sin la cobertura común
    )


  # 3. Ajuste por no respuesta ----

  aj <- ajustar_pesos(base, base$en_poblacion)
  base$fex_aj     <- aj$fex_aj
  base$celda_aj   <- aj$celda
  base$fex_aj_nac <- ajustar_pesos(base, base$en_poblacion_nac)$fex_aj


  # 4. Trazabilidad (Tabla 2): cuántos quedan después de cada criterio ----

  pasos <- list(
    "0. Ocupados (base cruda)"               = rep(TRUE, nrow(base)),
    "1. Edad >= 15"                          = base$f_edad,
    "2. Remunerados"                         = base$f_remunerado,
    "3. Cobertura común (24 dptos.)"         = base$f_cobertura,
    "4. Sin ingreso igual a 0"               = base$f_no_cero,
    "5. Dimensiones completas"               = base$f_dims,
    "6. Responden ingreso (entran al Theil)" = base$responde
  )
  acumulado <- rep(TRUE, nrow(base))
  for (p in names(pasos)) {
    acumulado <- acumulado & pasos[[p]]
    trazabilidad[[paste(anio, p)]] <- data.frame(
      anio = anio, paso = p, filas = sum(acumulado),
      pct_filas = round(100 * sum(acumulado) / nrow(base), 2),
      pct_fex   = round(100 * sum(base$FEX[acumulado]) / sum(base$FEX), 2)
    )
  }


  # 5. Columnas finales ----

  base <- base %>%
    select(ANIO, MES, DIRECTORIO, SECUENCIA_P, HOGAR, ORDEN,
           FEX, fex_aj, fex_aj_nac, celda_aj,
           ingreso, edad, horas,
           sexo, educ, formal, region, estrato, posicion, tam_empresa,
           DPTO, CLASE,
           starts_with("f_"), responde, en_poblacion, en_poblacion_nac)


  # 6. Verificaciones antes de guardar ----

  pob <- base$en_poblacion
  stopifnot(
    "Hay personas repetidas" = !anyDuplicated(base[c("MES", "DIRECTORIO", "SECUENCIA_P", "HOGAR", "ORDEN")]),
    "Hay FEX faltantes o no positivos"      = all(!is.na(base$FEX) & base$FEX > 0),
    "Quien responde debe tener ingreso > 0" = all(base$ingreso[base$responde] > 0),
    "fex_aj solo existe en la población"    = all(is.na(base$fex_aj) == !pob),
    "No respondientes con fex_aj = 0"       = all(base$fex_aj[pob & !base$responde] == 0),
    "fex_aj conserva el total del FEX"      =
      abs(sum(base$fex_aj[pob]) - sum(base$FEX[pob])) < 1e-8 * sum(base$FEX[pob])
  )

  escribir_csv_gz(base, paste0("data/final/geih_", anio, ".csv.gz"))
  cat(anio, "| ocupados:", nrow(base), "| población:", sum(pob),
      "| entran al Theil:", sum(pob & base$responde), "\n")
}

write.csv(bind_rows(trazabilidad), "outputs/trazabilidad.csv", row.names = FALSE)
