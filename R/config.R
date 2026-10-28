# =============================================================================
# Configuración común del proyecto
#
# Las constantes que usan varios scripts viven aquí, una sola vez.
# Cambiar un valor aquí lo cambia en todo el proyecto: no se cambia ninguno sin
# consultarlo con el equipo (ver CLAUDE.md, sección 4).
# =============================================================================

anios       <- 2018:2026                   # bases construidas (meses 1 a 6 de cada año)
anios_theil <- setdiff(anios, 2020)        # 2020 sin ingreso ni estrato (recolección telefónica)

dimensiones <- c("educ", "formal", "sexo", "region", "estrato")
