# =============================================================================
# Configuración común del proyecto
#
# Las constantes que usan varios scripts viven aquí, una sola vez.
# Cambiar un valor aquí lo cambia en todo el proyecto: no se cambia ninguno sin
# consultarlo con el equipo (ver CLAUDE.md, sección 4).
# =============================================================================


# Años y meses ----

anios       <- 2018:2026                   # bases construidas
meses       <- 1:6                         # meses de cada año
anios_theil <- setdiff(anios, 2020)        # 2020 sin ingreso ni estrato (recolección telefónica)

# Años que el DANE publica en un solo archivo nacional (sin Área/Cabecera/Resto)
anios_nacionales <- c(2020, 2022:2026)


# Población de estudio ----

edad_min <- 15        # el marco 2018 define ocupados desde 15 años; se aplica a todos

# Los 24 departamentos presentes en 201801 (marco antiguo). Los 9 que agrega el
# marco 2018 (81, 85, 86, 88, 91, 94, 95, 97, 99) quedan fuera de la serie comparable.
deptos_comunes <- c(5, 8, 11, 13, 15, 17, 18, 19, 20, 23, 25, 27,
                    41, 44, 47, 50, 52, 54, 63, 66, 68, 70, 73, 76)


# Ajuste de pesos por no respuesta ----

min_resp_celda <- 30  # mínimo de respondientes por celda


# Descomposición ----

dimensiones <- c("educ", "formal", "sexo", "region", "estrato")


# Descriptiva ----

anio_ref  <- 2026     # año principal de la descriptiva y de la inferencia clásica
anio_base <- 2018     # año de comparación

# Salario mínimo mensual (SMMLV), pesos corrientes. Decretos anuales del
# Gobierno nacional. Sirve para expresar el ingreso en salarios mínimos.
smmlv <- c(
  "2017" =  737717, "2018" =  781242, "2019" =  828116, "2020" =  877803,
  "2021" =  908526, "2022" = 1000000, "2023" = 1160000, "2024" = 1300000,
  "2025" = 1423500, "2026" = 1750905
)


# Semillas (todo lo aleatorio debe ser reproducible) ----

semilla_descriptiva <- 2026   # submuestra de la figura de dispersión
semilla_inferencia  <- 2026   # submuestra de las pruebas clásicas


# Inferencia clásica (P1–P7, docs/alineacion_curso.md) ----
# Las pruebas del curso suponen muestreo aleatorio simple. Se aplican sobre una
# submuestra sacada con probabilidad proporcional a fex_aj, que representa a la
# población de ocupados (aprobado por el equipo: decisión D12).

n_inferencia <- 2000     # tamaño de la submuestra de las pruebas clásicas
n_normalidad <- 5000     # tamaño para Shapiro-Wilk (R admite máximo 5.000)
anio_normalidad <- 2024  # año de la revisión de lognormalidad (= año de la simulación)
alfa <- 0.05             # nivel de significancia de todas las pruebas
