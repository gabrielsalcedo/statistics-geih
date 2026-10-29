# =============================================================================
# Guardar tablas y figuras para el informe
#
# Cada tabla se guarda dos veces en outputs/tablas/:
#   <nombre>.csv  para revisarla o abrirla en otro programa
#   <nombre>.tex  un tabular de LaTeX (booktabs) que el informe incluye con \input{}
# Cada figura se guarda en PDF en outputs/figuras/ para \includegraphics{}.
#
# Así el informe nunca copia números a mano: si cambian los datos, se vuelve a
# correr R y se recompila LaTeX.
# =============================================================================


ruta_tablas  <- here::here("outputs", "tablas")
ruta_figuras <- here::here("outputs", "figuras")
dir.create(ruta_tablas,  showWarnings = FALSE, recursive = TRUE)
dir.create(ruta_figuras, showWarnings = FALSE, recursive = TRUE)


# Texto a LaTeX ----
# Escapa los caracteres especiales y cambia símbolos Unicode que pdfLaTeX no
# conoce por su versión matemática.

simbolos <- c(
  "\\" = "\\textbackslash{}", "%" = "\\%", "&" = "\\&", "#" = "\\#", "_" = "\\_", "$" = "\\$",
  "≈" = "$\\approx$", "×" = "$\\times$", "≤" = "$\\leq$", "≥" = "$\\geq$", "∝" = "$\\propto$",
  "σ²" = "$\\sigma^2$", "σ" = "$\\sigma$", "μ" = "$\\mu$", "β" = "$\\beta$", "χ²" = "$\\chi^2$"
)

a_latex <- function(x) {
  x <- as.character(x)
  for (s in names(simbolos)) x <- gsub(s, simbolos[[s]], x, fixed = TRUE)
  x
}


# Número a texto en formato colombiano (coma decimal, punto de miles) ----
# Los valores p muy pequeños se escriben en notación científica.

formatear <- function(x) {
  ifelse(
    is.na(x), "—",
    ifelse(is.infinite(x), ifelse(x > 0, "$\\infty$", "$-\\infty$"),   # IC unilaterales
    ifelse(
      x != 0 & abs(x) < 1e-3,
      paste0("$", sub("e", " \\\\times 10^{", formatC(x, format = "e", digits = 2, decimal.mark = ",")), "}$"),
      formatC(x, format = "f", digits = 3, big.mark = ".", decimal.mark = ",", drop0trailing = TRUE)
    ))
  )
}


# Tabla ----

guardar_tabla <- function(t, nombre) {

  write.csv(t, file.path(ruta_tablas, paste0(nombre, ".csv")), row.names = FALSE)

  d <- as.data.frame(t)
  celdas <- sapply(d, function(col) if (is.numeric(col)) formatear(col) else a_latex(ifelse(is.na(col), "—", col)))
  celdas <- matrix(celdas, nrow = nrow(d))   # una sola fila también queda como matriz

  alineacion <- paste(ifelse(sapply(d, is.numeric), "r", "l"), collapse = "")

  lineas <- c(
    paste0("% Generado por R (", nombre, "). No editar a mano."),
    paste0("\\begin{tabular}{", alineacion, "}"),
    "\\toprule",
    paste0(paste(a_latex(names(d)), collapse = " & "), " \\\\"),
    "\\midrule",
    paste0(apply(celdas, 1, paste, collapse = " & "), " \\\\"),
    "\\bottomrule",
    "\\end{tabular}"
  )
  writeLines(lineas, file.path(ruta_tablas, paste0(nombre, ".tex")), useBytes = TRUE)

  t
}


# Figuras ----
# cairo_pdf conserva las tildes y símbolos como ≈ en los títulos.

guardar_figura <- function(g, nombre, ancho = 8, alto = 5) {
  ggplot2::ggsave(file.path(ruta_figuras, paste0(nombre, ".pdf")), g,
                  width = ancho, height = alto, device = grDevices::cairo_pdf)
  invisible(g)   # invisible: si no, R imprime el gráfico y crea un Rplots.pdf suelto
}

# Para gráficos de R base: abrir_pdf("nombre"); plot(...); dev.off()
abrir_pdf <- function(nombre, ancho = 10, alto = 5) {
  grDevices::cairo_pdf(file.path(ruta_figuras, paste0(nombre, ".pdf")), width = ancho, height = alto)
}
