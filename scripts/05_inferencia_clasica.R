# =============================================================================
# ETAPA 5 — Inferencia clásica (propuestas P1–P7, docs/alineacion_curso.md)
#
# Intervalos de confianza, pruebas t, F y chi-cuadrado, regresión lineal simple
# y bondad de ajuste, con los procedimientos vistos en el curso.
#
# Por qué una submuestra:
#   Las fórmulas del curso suponen una muestra aleatoria simple. La GEIH no lo
#   es (tiene factores de expansión) y con n ≈ 155.000 todo resulta
#   significativo. Por eso cada prueba se hace sobre una submuestra de
#   n_inferencia personas sacada CON probabilidad proporcional a fex_aj: así la
#   submuestra representa a la población de ocupados y las fórmulas se aplican
#   tal cual, sin pesos. Limitación: ignora los conglomerados de la encuesta.
#
# Entrada: data/processed/geih_<año>.csv.gz
# Salida:  outputs/inferencia/tablas/*.csv  y  outputs/inferencia/figuras/*.png
# =============================================================================


# Librerías ----

library(here)
library(dplyr)

source(here("R", "config.R"))
source(here("R", "datos.R"))

ruta_tab <- here("outputs", "inferencia", "tablas")
ruta_fig <- here("outputs", "inferencia", "figuras")
dir.create(ruta_tab, showWarnings = FALSE, recursive = TRUE)
dir.create(ruta_fig, showWarnings = FALSE, recursive = TRUE)

guardar_tabla <- function(t, nombre) {
  write.csv(t, file.path(ruta_tab, paste0(nombre, ".csv")), row.names = FALSE)
  t
}


# Submuestra proporcional al peso ----
# Con reemplazo y probabilidad ∝ fex_aj: cada persona de la submuestra
# "representa" lo mismo, como en un muestreo aleatorio simple de la población.

submuestra <- function(anio, n) {
  b <- cargar_analitica(anio) %>%
    filter(en_poblacion, responde) %>%
    mutate(ln_ingreso = log(ingreso))
  set.seed(semilla_inferencia)
  b[sample(nrow(b), n, replace = TRUE, prob = b$fex_aj), ]
}

s <- submuestra(anio_ref, n_inferencia)

# Cada prueba agrega una fila a esta tabla resumen
resumen <- list()

agregar <- function(id, analisis, h0, estadistico, gl, p, estimacion, ic = c(NA, NA), efecto = NA) {
  resumen[[id]] <<- data.frame(
    id = id, analisis = analisis, h0 = h0,
    estadistico = estadistico,
    gl = if (all(is.na(gl))) NA_character_ else paste(round(gl, 1), collapse = ", "),  # F tiene dos
    valor_p = p,
    estimacion = estimacion, ic_inf = ic[1], ic_sup = ic[2], efecto = efecto,
    decision = ifelse(is.na(p), NA, ifelse(p < alfa, "Se rechaza H0", "No se rechaza H0"))
  )
}


# =============================================================================
# P1. IC del 95 % para la media de ln(ingreso), cada año (t)
# =============================================================================
# x̄ ± t(n-1; 0,975) · s / √n

p1 <- bind_rows(lapply(anios_theil, function(a) {
  x  <- submuestra(a, n_inferencia)$ln_ingreso
  ic <- t.test(x, conf.level = 1 - alfa)$conf.int
  data.frame(anio = a, n = length(x), media = mean(x), ic_inf = ic[1], ic_sup = ic[2])
})) %>%
  guardar_tabla("p1_ic_media_ln_ingreso")

t1 <- t.test(s$ln_ingreso, conf.level = 1 - alfa)
agregar("P1", paste("IC media de ln(ingreso),", anio_ref), "—",
        NA, NA, NA, mean(s$ln_ingreso), t1$conf.int)


# =============================================================================
# P2. IC del 95 % para la proporción de informales (z)
# =============================================================================
# p̂ ± z(0,975) · √(p̂(1 - p̂) / n). Válido porque n·p̂ y n·(1 - p̂) son > 10.

p_inf <- mean(s$formal == "Informal")
ee    <- sqrt(p_inf * (1 - p_inf) / n_inferencia)
z     <- qnorm(1 - alfa / 2)

agregar("P2", paste("IC proporción de informales,", anio_ref), "—",
        NA, NA, NA, p_inf, c(p_inf - z * ee, p_inf + z * ee))


# =============================================================================
# P3. ¿Ganan más los formales? t de Welch unilateral sobre ln(ingreso)
# =============================================================================
# H0: μ_formal ≤ μ_informal   H1: μ_formal > μ_informal
# Welch no supone varianzas iguales (P4 muestra que son distintas).

t3 <- t.test(ln_ingreso ~ formal, data = s, alternative = "greater", conf.level = 1 - alfa)
dif <- unname(t3$estimate[1] - t3$estimate[2])

agregar("P3", "t de Welch: ln(ingreso) formal > informal", "μ_formal ≤ μ_informal",
        unname(t3$statistic), unname(t3$parameter), t3$p.value, dif, unname(t3$conf.int),
        efecto = exp(dif))   # razón de ingresos (medias geométricas) formal / informal


# =============================================================================
# P4. ¿Es más desigual el ingreso informal? F de razón de varianzas
# =============================================================================
# Var(ln y) es la medida de desigualdad que estima D (T = σ²/2).
# H0: σ²_formal = σ²_informal  (bilateral)
# F supone normalidad de ln(y), que no se cumple (P7). Por eso se agrega
# Brown-Forsythe: ANOVA sobre |y - mediana del grupo|, robusto a la no normalidad.

t4 <- var.test(ln_ingreso ~ formal, data = s, conf.level = 1 - alfa)

agregar("P4", "F: Var ln(ingreso) formal / informal", "σ²_formal = σ²_informal",
        unname(t4$statistic), unname(t4$parameter), t4$p.value,
        unname(t4$estimate), unname(t4$conf.int))

bf <- s %>%
  group_by(formal) %>%
  mutate(desv = abs(ln_ingreso - median(ln_ingreso))) %>%
  ungroup()
bf <- anova(lm(desv ~ formal, data = bf))

agregar("P4b", "Brown-Forsythe: dispersión formal vs informal", "misma dispersión",
        bf$`F value`[1], bf$Df, bf$`Pr(>F)`[1], NA)


# =============================================================================
# P5. ¿Formalidad y educación son independientes? Chi-cuadrado
# =============================================================================
# H0: independencia. V de Cramér mide la fuerza de la asociación (0 a 1).

tabla5 <- table(educ = s$educ, formal = s$formal)
t5     <- chisq.test(tabla5)
v      <- sqrt(unname(t5$statistic) / (n_inferencia * (min(dim(tabla5)) - 1)))

if (any(t5$expected < 5)) warning("P5: hay frecuencias esperadas menores que 5.")

guardar_tabla(as.data.frame.matrix(tabla5) %>% mutate(educ = rownames(.), .before = 1),
              "p5_tabla_educ_formal")

agregar("P5", "Chi-cuadrado: educación × formalidad", "independencia",
        unname(t5$statistic), unname(t5$parameter), t5$p.value, NA, efecto = v)


# =============================================================================
# P6. Regresión lineal simple: ln(ingreso) = β0 + β1 · horas + error
# =============================================================================
# Prueba de β1 (t), R² y revisión de supuestos de los residuos:
#   normalidad (QQ-plot y Shapiro-Wilk), homocedasticidad (Breusch-Pagan) e
#   independencia (por construcción del muestreo).

m6  <- lm(ln_ingreso ~ horas, data = s)
sm6 <- summary(m6)

coef6 <- data.frame(
  termino   = rownames(sm6$coefficients),
  estimador = sm6$coefficients[, 1],
  ee        = sm6$coefficients[, 2],
  t         = sm6$coefficients[, 3],
  valor_p   = sm6$coefficients[, 4],
  ic_inf    = confint(m6, level = 1 - alfa)[, 1],
  ic_sup    = confint(m6, level = 1 - alfa)[, 2],
  row.names = NULL
)
guardar_tabla(coef6, "p6_regresion_coeficientes")

agregar("P6", "Regresión: pendiente de horas en ln(ingreso)", "β1 = 0",
        coef6$t[2], m6$df.residual, coef6$valor_p[2], coef6$estimador[2],
        c(coef6$ic_inf[2], coef6$ic_sup[2]), efecto = sm6$r.squared)

# Normalidad de los residuos
sw6 <- shapiro.test(residuals(m6))
agregar("P6a", "Supuesto: normalidad de los residuos (Shapiro-Wilk)", "residuos normales",
        unname(sw6$statistic), NA, sw6$p.value, NA)

# Homocedasticidad: Breusch-Pagan. Se regresan los residuos al cuadrado sobre
# horas; si la varianza no depende de horas, n · R² ~ chi-cuadrado con 1 gl.
bp <- n_inferencia * summary(lm(residuals(m6)^2 ~ s$horas))$r.squared
agregar("P6b", "Supuesto: homocedasticidad (Breusch-Pagan)", "varianza constante",
        bp, 1, pchisq(bp, df = 1, lower.tail = FALSE), NA)

png(file.path(ruta_fig, "p6_residuos.png"), width = 1600, height = 800, res = 150)
par(mfrow = c(1, 2))
plot(fitted(m6), residuals(m6), pch = 16, cex = 0.4, col = "#2c7fb880",
     xlab = "Valores ajustados", ylab = "Residuos", main = "Residuos frente a ajustados")
abline(h = 0, col = "#e34a33", lwd = 2)
qqnorm(residuals(m6), pch = 16, cex = 0.4, main = "QQ-plot normal de los residuos")
qqline(residuals(m6), col = "#e34a33", lwd = 2)
dev.off()


# =============================================================================
# P7. ¿Es lognormal el ingreso? Bondad de ajuste de ln(ingreso)
# =============================================================================
# Primero la gráfica (histograma y QQ-plot); la prueba es un complemento.
# shapiro.test admite máximo 5.000 datos, y con muestras grandes rechaza ante
# cualquier desviación, por eso se usa una submuestra.

s7  <- submuestra(anio_normalidad, n_normalidad)
sw7 <- shapiro.test(s7$ln_ingreso)

agregar("P7", paste("Shapiro-Wilk: ln(ingreso) normal,", anio_normalidad), "ln(ingreso) normal",
        unname(sw7$statistic), NA, sw7$p.value, NA)

png(file.path(ruta_fig, "p7_ln_ingreso_normalidad.png"), width = 1600, height = 800, res = 150)
par(mfrow = c(1, 2))
hist(s7$ln_ingreso, breaks = 60, freq = FALSE, col = "#a6bddb", border = "white",
     main = paste0("ln(ingreso), ", anio_normalidad), xlab = "ln(ingreso laboral)", ylab = "Densidad")
curve(dnorm(x, mean(s7$ln_ingreso), sd(s7$ln_ingreso)), add = TRUE, col = "#e34a33", lwd = 2)
qqnorm(s7$ln_ingreso, pch = 16, cex = 0.4, main = "QQ-plot normal de ln(ingreso)")
qqline(s7$ln_ingreso, col = "#e34a33", lwd = 2)
dev.off()


# =============================================================================
# Tabla resumen
# =============================================================================

resumen <- bind_rows(resumen) %>%
  mutate(across(c(estadistico, estimacion, ic_inf, ic_sup, efecto), ~ round(.x, 4)),
         valor_p = signif(valor_p, 3)) %>%
  guardar_tabla("resumen_pruebas")

cat("\nInferencia clásica (submuestra de", n_inferencia, "∝ fex_aj,", anio_ref, "):\n")
print(resumen %>% select(id, analisis, estadistico, valor_p, estimacion, ic_inf, ic_sup, efecto, decision),
      row.names = FALSE)
cat("\nListo. Tablas en", ruta_tab, "y figuras en", ruta_fig, "\n")
