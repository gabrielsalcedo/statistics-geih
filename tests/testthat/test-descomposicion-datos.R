# =============================================================================
# Descomposición sobre los datos reales: between + within = total y
# within = suma de s_k * T_k, en cada año y cada dimensión.
# Usa las bases de data/processed/ (versionadas en GitHub).
# =============================================================================

source(here::here("R", "config.R"))
source(here::here("R", "datos.R"))

test_that("la descomposición cuadra en cada año y dimensión (fex_aj)", {
  skip_if_not(all(file.exists(ruta_procesada(anios_theil))), "No están las bases de data/processed/.")

  for (anio in anios_theil) {
    b <- cargar_analitica(anio)
    b <- b[b$en_poblacion & b$responde, ]
    T_total <- theil_A(b$ingreso, b$fex_aj)

    for (d in dimensiones) {
      r <- theil_decomp(b$ingreso, b$fex_aj, b[[d]])
      info <- paste(anio, d)
      expect_equal(r$total$T, T_total, info = info)
      expect_equal(r$total$T_B + r$total$T_W, T_total, tolerance = 1e-10, info = info)
      expect_equal(sum(r$grupos$s_k * r$grupos$T_k), r$total$T_W, tolerance = 1e-10, info = info)
    }
  }
})
