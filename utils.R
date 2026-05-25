# utils.R — Funções auxiliares para o projeto Ocean Analysis
# ============================================================

# ---- Dependências ----
PACKAGES <- c(
  "ncdf4", "oce", "gsw", "ggplot2", "tidyverse",
  "patchwork", "rnaturalearth", "rnaturalearthdata",
  "sf", "lubridate", "cmocean", "metR"
)

install_dependencies <- function() {
  missing <- PACKAGES[!PACKAGES %in% installed.packages()[, "Package"]]
  if (length(missing) > 0) {
    message("Instalando pacotes: ", paste(missing, collapse = ", "))
    install.packages(missing)
  } else {
    message("Todas as dependências já estão instaladas.")
  }
}

load_dependencies <- function() {
  invisible(lapply(PACKAGES, library, character.only = TRUE))
}

# ---- Paths ----
path_raw       <- here::here("data", "raw")
path_processed <- here::here("data", "processed")
path_figures   <- here::here("outputs", "figures")
path_tables    <- here::here("outputs", "tables")

# Cria diretórios se não existirem
create_dirs <- function() {
  dirs <- c(path_raw, path_processed, path_figures, path_tables)
  lapply(dirs, dir.create, showWarnings = FALSE, recursive = TRUE)
  invisible(NULL)
}

# ---- Funções Oceanográficas ----

#' Calcula densidade potencial (sigma-theta) usando TEOS-10
#' @param SA Salinidade absoluta (g/kg)
#' @param CT Temperatura conservativa (°C)
#' @param p_ref Pressão de referência em dbar (default = 0)
calc_sigma_theta <- function(SA, CT, p_ref = 0) {
  gsw::gsw_sigma0(SA, CT)
}

#' Converte salinidade prática para absoluta (TEOS-10)
#' @param SP Salinidade prática (PSU)
#' @param p  Pressão (dbar)
#' @param lon Longitude
#' @param lat Latitude
sp_to_sa <- function(SP, p, lon, lat) {
  gsw::gsw_SA_from_SP(SP, p, lon, lat)
}

#' Converte temperatura potencial para conservativa (TEOS-10)
#' @param SA Salinidade absoluta (g/kg)
#' @param t  Temperatura in-situ (°C)
#' @param p  Pressão (dbar)
t_to_ct <- function(SA, t, p) {
  pt <- gsw::gsw_pt0_from_t(SA, t, p)
  gsw::gsw_CT_from_pt(SA, pt)
}

# ---- Tema ggplot oceanográfico ----
theme_ocean <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background  = element_rect(fill = "#f0f4f8", color = NA),
      panel.background = element_rect(fill = "#e8f1f8", color = NA),
      panel.grid.major = element_line(color = "#c5d8ea", linewidth = 0.4),
      panel.grid.minor = element_blank(),
      plot.title       = element_text(face = "bold", size = base_size + 2),
      plot.subtitle    = element_text(color = "grey40"),
      axis.title       = element_text(face = "bold"),
      legend.background = element_rect(fill = "white", color = NA)
    )
}

# ---- Utilidades gerais ----

#' Salva figura com nome padronizado
#' @param plot  Objeto ggplot
#' @param name  Nome descritivo (sem data, sem extensão)
#' @param w     Largura em cm (default 20)
#' @param h     Altura em cm (default 14)
save_figure <- function(plot, name, w = 20, h = 14) {
  filename <- paste0(format(Sys.Date(), "%Y%m%d"), "_", name, ".png")
  filepath <- file.path(path_figures, filename)
  ggsave(filepath, plot = plot, width = w, height = h,
         units = "cm", dpi = 300, bg = "white")
  message("Figura salva: ", filepath)
  invisible(filepath)
}
