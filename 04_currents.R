# 04_currents.R — Análise de correntes oceânicas
# ================================================
# Velocidade, direção, magnitude, vorticidade relativa

source("R/utils.R")
load_dependencies()

# ============================================================
# 1. MAGNITUDE E DIREÇÃO DA CORRENTE
# ============================================================

compute_current_stats <- function(df, u_col = "u", v_col = "v") {
  df <- dplyr::mutate(df,
    speed     = sqrt(.data[[u_col]]^2 + .data[[v_col]]^2),
    direction = (atan2(.data[[u_col]], .data[[v_col]]) * 180 / pi) %% 360,
    EKE       = 0.5 * (.data[[u_col]]^2 + .data[[v_col]]^2)  # Energia cinética de redemoinho
  )
  return(df)
}

# ============================================================
# 2. MAPA DE CORRENTES (vetores + magnitude de fundo)
# ============================================================

plot_current_map <- function(df, lon_range = NULL, lat_range = NULL,
                              scale = 0.5, title = "Correntes Oceânicas") {
  world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

  # Define limites automaticamente se não fornecidos
  if (is.null(lon_range)) lon_range <- range(df$lon, na.rm = TRUE) + c(-1, 1)
  if (is.null(lat_range)) lat_range <- range(df$lat, na.rm = TRUE) + c(-1, 1)

  p <- ggplot2::ggplot(df) +
    ggplot2::geom_raster(
      ggplot2::aes(x = lon, y = lat, fill = speed),
      interpolate = TRUE
    ) +
    ggplot2::scale_fill_gradientn(
      colors = cmocean::cmocean("speed")(256),
      name   = "Velocidade\n(m/s)"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x    = lon,
        y    = lat,
        xend = lon + u * scale,
        yend = lat + v * scale
      ),
      arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm")),
      linewidth = 0.3, color = "white", alpha = 0.7
    ) +
    ggplot2::geom_sf(data = world, fill = "grey30", color = "grey50",
                     linewidth = 0.3, inherit.aes = FALSE) +
    ggplot2::coord_sf(xlim = lon_range, ylim = lat_range, expand = FALSE) +
    ggplot2::labs(
      title    = title,
      x        = "Longitude",
      y        = "Latitude"
    ) +
    theme_ocean() +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(color = "grey40", fill = NA)
    )

  return(p)
}

# ============================================================
# 3. ROSA DOS VENTOS / CORRENTES (frequência por direção)
# ============================================================

plot_current_rose <- function(df, n_bins = 16, title = "Rosa das Correntes") {
  # Discretiza direção em setores
  df <- dplyr::mutate(df,
    dir_bin = cut(
      direction,
      breaks = seq(0, 360, length.out = n_bins + 1),
      labels = seq(0, 360 - 360/n_bins, by = 360/n_bins),
      include.lowest = TRUE
    ),
    speed_class = cut(
      speed,
      breaks = c(0, 0.1, 0.2, 0.4, 0.6, Inf),
      labels = c("< 0.1", "0.1–0.2", "0.2–0.4", "0.4–0.6", "> 0.6")
    )
  )

  freq <- dplyr::count(df, dir_bin, speed_class) |>
    dplyr::mutate(dir_num = as.numeric(as.character(dir_bin)))

  p <- ggplot2::ggplot(freq,
      ggplot2::aes(x = dir_num, y = n, fill = speed_class)) +
    ggplot2::geom_col(width = 360 / n_bins, color = "white", linewidth = 0.2) +
    ggplot2::coord_polar(start = 0) +
    ggplot2::scale_x_continuous(
      limits = c(0, 360),
      breaks = c(0, 90, 180, 270),
      labels = c("N", "E", "S", "W")
    ) +
    ggplot2::scale_fill_brewer(palette = "YlOrRd", name = "Velocidade (m/s)") +
    ggplot2::labs(title = title, x = NULL, y = "Frequência") +
    theme_ocean()

  return(p)
}

# ============================================================
# 4. SÉRIE TEMPORAL DE VELOCIDADE
# ============================================================

plot_speed_timeseries <- function(df, date_col = "date",
                                   smooth = TRUE, title = "Velocidade ao longo do tempo") {
  p <- ggplot2::ggplot(df,
      ggplot2::aes(x = .data[[date_col]], y = speed)) +
    ggplot2::geom_line(color = "#1976D2", linewidth = 0.5, alpha = 0.7)

  if (smooth) {
    p <- p + ggplot2::geom_smooth(
      method = "loess", span = 0.2,
      color = "#E53935", fill = "#EF9A9A", linewidth = 1
    )
  }

  p <- p +
    ggplot2::labs(
      title = title,
      x     = "Data",
      y     = "Velocidade (m/s)"
    ) +
    theme_ocean()

  return(p)
}

# ============================================================
# EXEMPLO
# ============================================================

# df_curr <- readRDS(file.path(path_processed, "currents_processed.rds"))
# df_curr <- compute_current_stats(df_curr)
#
# p_map  <- plot_current_map(df_curr, title = "Correntes — Atlântico Sul")
# p_rose <- plot_current_rose(df_curr)
# p_ts   <- plot_speed_timeseries(df_curr)
#
# layout <- (p_map) / (p_rose | p_ts)
# save_figure(layout, "currents_overview", w = 28, h = 22)
