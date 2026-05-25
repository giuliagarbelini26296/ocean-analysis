# 03_ts_diagram.R — Diagrama T-S e identificação de massas d'água
# ================================================================

source("R/utils.R")
load_dependencies()

# ============================================================
# 1. ISOPICNAIS (linhas de densidade constante)
# ============================================================

make_isopycnals <- function(t_range = c(-2, 32), s_range = c(30, 40),
                             n = 200) {
  grid <- expand.grid(
    CT = seq(t_range[1], t_range[2], length.out = n),
    SA = seq(s_range[1], s_range[2], length.out = n)
  )
  grid$sigma0 <- gsw::gsw_sigma0(grid$SA, grid$CT)
  return(grid)
}

# ============================================================
# 2. MASSAS D'ÁGUA DO ATLÂNTICO SUL (referência)
# ============================================================
# Adapte conforme sua região de estudo

water_masses_SA <- tibble::tribble(
  ~name,  ~SA_min, ~SA_max, ~CT_min, ~CT_max, ~color,
  "ACAS", 35.4,    36.4,     6,       18,      "#2196F3",  # Água Central do Atlântico Sul
  "AIA",  34.2,    34.5,     2,        5,      "#00BCD4",  # Água Intermediária Antártica
  "APAN", 34.6,    34.9,     1.5,      4,      "#9C27B0",  # Água Profunda do Atlântico Norte
  "AA",   34.64,   34.72,   -0.8,      1.8,    "#3F51B5"   # Água Antártica de Fundo
)

# ============================================================
# 3. DIAGRAMA T-S
# ============================================================

plot_ts_diagram <- function(df, color_by = "depth",
                             show_isopycnals = TRUE,
                             show_water_masses = TRUE,
                             title = "Diagrama T-S") {

  # Isopicnais
  iso <- make_isopycnals(
    t_range = range(df$CT, na.rm = TRUE) + c(-1, 1),
    s_range = range(df$SA, na.rm = TRUE) + c(-0.5, 0.5)
  )

  p <- ggplot2::ggplot()

  if (show_isopycnals) {
    p <- p +
      ggplot2::geom_contour(
        data = iso,
        ggplot2::aes(x = SA, y = CT, z = sigma0),
        color = "grey70", linewidth = 0.3, linetype = "dashed",
        breaks = seq(20, 30, by = 0.5)
      ) +
      metR::geom_text_contour(
        data = iso,
        ggplot2::aes(x = SA, y = CT, z = sigma0),
        breaks = seq(20, 30, by = 1),
        color = "grey50", size = 3, skip = 0
      )
  }

  # Dados
  if (color_by == "depth") {
    p <- p +
      ggplot2::geom_point(
        data = df,
        ggplot2::aes(x = SA, y = CT, color = pres),
        size = 0.8, alpha = 0.6
      ) +
      ggplot2::scale_color_gradientn(
        colors = rev(cmocean::cmocean("deep")(256)),
        name = "Pressão (dbar)"
      )
  } else {
    p <- p +
      ggplot2::geom_point(
        data = df,
        ggplot2::aes(x = SA, y = CT, color = .data[[color_by]]),
        size = 0.8, alpha = 0.6
      )
  }

  # Regiões de massas d'água
  if (show_water_masses) {
    p <- p +
      ggplot2::geom_rect(
        data = water_masses_SA,
        ggplot2::aes(xmin = SA_min, xmax = SA_max,
                     ymin = CT_min, ymax = CT_max,
                     fill = name),
        alpha = 0.12, color = NA, inherit.aes = FALSE
      ) +
      ggplot2::geom_label(
        data = water_masses_SA,
        ggplot2::aes(
          x = (SA_min + SA_max) / 2,
          y = (CT_min + CT_max) / 2,
          label = name, color = name
        ),
        size = 3, fontface = "bold", fill = "white",
        label.padding = ggplot2::unit(0.15, "lines"),
        inherit.aes = FALSE
      ) +
      ggplot2::scale_fill_manual(
        values = setNames(water_masses_SA$color, water_masses_SA$name),
        guide = "none"
      ) +
      ggplot2::scale_color_manual(
        values = setNames(water_masses_SA$color, water_masses_SA$name),
        guide = "none"
      )
  }

  p <- p +
    ggplot2::labs(
      title    = title,
      subtitle = paste0(nrow(df), " observações | padrão TEOS-10"),
      x        = "Salinidade Absoluta (g/kg)",
      y        = "Temperatura Conservativa (°C)"
    ) +
    theme_ocean()

  return(p)
}

# ============================================================
# 4. PERFIL VERTICAL T e S
# ============================================================

plot_profiles <- function(df, max_depth = 2000) {
  df_deep <- dplyr::filter(df, pres <= max_depth)

  p_temp <- ggplot2::ggplot(df_deep,
      ggplot2::aes(x = CT, y = -pres, group = interaction(lon, lat, date))) +
    ggplot2::geom_line(alpha = 0.3, color = "#E53935", linewidth = 0.4) +
    ggplot2::labs(x = "Temperatura Conservativa (°C)", y = "Profundidade (dbar)") +
    theme_ocean()

  p_salt <- ggplot2::ggplot(df_deep,
      ggplot2::aes(x = SA, y = -pres, group = interaction(lon, lat, date))) +
    ggplot2::geom_line(alpha = 0.3, color = "#1565C0", linewidth = 0.4) +
    ggplot2::labs(x = "Salinidade Absoluta (g/kg)", y = NULL) +
    theme_ocean()

  patchwork::wrap_plots(p_temp, p_salt, ncol = 2) +
    patchwork::plot_annotation(
      title = "Perfis Verticais de Temperatura e Salinidade",
      theme = ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))
    )
}

# ============================================================
# EXEMPLO
# ============================================================

# df <- readRDS(file.path(path_processed, "argo_qc_clean.rds"))
# p_ts  <- plot_ts_diagram(df, title = "Diagrama T-S — Atlântico Sul")
# p_prf <- plot_profiles(df)
# save_figure(p_ts,  "ts_diagram")
# save_figure(p_prf, "profiles_T_S")
