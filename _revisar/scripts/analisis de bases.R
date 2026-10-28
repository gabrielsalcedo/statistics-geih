library(dplyr)
library(tidyr)
library(janitor)
library(readxl)
library(writexl)

# URL base del repositorio (usa el mismo commit que tenías en tu enlace de
# GitHub, para asegurar que siempre apunte a esta versión exacta de los
# archivos). Si prefieres siempre la última versión de la rama principal,
# cambia "commit" por "main".
commit   <- "62c2000665cec5de526972530269f486dac2f6a8"
base_url <- paste0(
  "https://raw.githubusercontent.com/gabrielsalcedo/statistics-geih/",
  commit, "/data/raw/"
)

# Data frame donde se acumulan los resultados
datos_historica <- data.frame(
  anio   = integer(),
  income = numeric()
)

for (i in 2018:2020) {
  
  # 1. Construir la URL del archivo de ese año
  url_i <- paste0(base_url, i, ".xlsx")
  
  # 2. Descargar el archivo a un temporal (read_excel no puede leer
  #    directamente desde una URL, necesita un archivo local)
  archivo_temp <- tempfile(fileext = ".xlsx")
  download.file(url_i, archivo_temp, mode = "wb", quiet = TRUE)
  
  # 3. Leer el archivo. OJO: el archivo de 2018 tiene la columna escrita
  #    como "incone" en vez de "income", así que renombramos por posición
  #    (columna 2) para que funcione igual en los tres años.
  base_i <- read_excel(archivo_temp) %>%
    rename(income = 2)
  
  # 4. Calcular el promedio de ingreso de ese año
  promedio <- mean(base_i$income, na.rm = TRUE)
  
  # 5. Agregar la fila al histórico
  datos_historica <- datos_historica %>%
    add_row(anio = i, income = promedio)
  
  # 6. Limpiar el temporal
  file.remove(archivo_temp)
}

print(datos_historica)
