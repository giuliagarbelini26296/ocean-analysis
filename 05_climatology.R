# 05_climatology.R — Climatologia e anomalias oceânicas
# =======================================================
# Calcula médias climatológicas mensais e anomalias

source("R/utils.R")
load_dependencies()

# ============================================================
# 1. CLIMATOLOGIA MENSAL
# ============================================================

compute_monthly_climatology <- function(df, var, date_col = "date",
                                         lon_col = "lon", lat_col = "lat",
                                         baseline_years = NULL) {
  df <- dplyr::mutate(df,
    year  = lubridate::year(.data[[date_col]]),
    month = lubridate::month(.data[[date_col]])
  )

  if (!is.null(baseline_years)) {
    df <- dplyr::filter(df, year %in% baseline_years)
    message("Climatologia calculada com baseline: ",
            min(baseline_years), "–", max(baseline_years))
  }

  clim <- df |>
    dplyr::group_by(.data[[lon_col]], .data[[lat_col]], month) |>
    dplyr::summarise(
      clim_mean = mean(.data[[var]], na.rm = TRUE),
      clim_sd   = sd(.data[[var]],   na.rm = TRUE),
      n_obs     = dplyr::n(),
      .groups   = "drop"
    )

  return(clim)
}

# ============================================================
# 2. ANOMALIAS
# ============================================================

compute_anomalies <- function(df, clim, var,
                               date_col = "date",
                               lon_col = "lon", lat_col = "lat") {
  df <- dplyr::mutate(df,
    month = lubridate::month(.data[[date_col]])
  )

  df_anom <- dplyr::left_join(
    df, clim,
    by = c(lon_col, lat_col, "month")
  ) |>
    dplyr::mutate(
      anomaly          = .data[[var]] - clim_mean,
      anomaly_norm     = anomaly / clim_sd,  # Anomalia normalizada (sigma)
      is_extreme_warm  = anomaly_norm >  1.5,
      is_extreme_cold  = anomaly_norm < -1.5
    )

  return(df_anom)
}

# ============================================================
# 3. CICLO SAZONAL MÉDIO
# ============================================================

plot_seasonal_cycle <- function(clim, var_label = "Temperatura (°C)",
                                 title = "Ciclo Sazonal") {
  month_labels <- c("Jan","Fev","Mar","Abr","Mai","Jun",
                    "Jul","Ago","Set","Out","Nov","Dez")

  clim_avg <- clim |>
    dplyr::group_by(month) |>
    dplyr::summarise(
      mean_val = mean(clim_mean, na.rm = TRUE),
      sd_val   = mean(clim_sd,   na.rm = TRUE),
      .groups  = "drop"
    )

  ggplot2::ggplot(clim_avg,
      ggplot2::aes(x = month, y = mean_val)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = mean_val - sd_val, ymax = mean_val + sd_val),
      fill = "#90CAF9", alpha = 0.4
    ) +
    ggplot2::geom_line(color = "#1565C0", linewidth = 1.2) +
    ggplot2::geom_point(color = "#1565C0", size = 2.5) +
    ggplot2::scale_x_continuous(breaks = 1:12, labels = month_labels) +
    ggplot2::labs(
      title    = title,
      subtitle = "Média ± 1 desvio padrão",
      x        = "Mês",
      y        = var_label
    ) +
    theme_ocean()
}

# ============================================================
# 4. MAPA DE ANOMALIAS
# ============================================================

plot_anomaly_map <- function(df_anom, lon_col = "lon", lat_col = "lat",
                              lon_range = NULL, lat_range = NULL,
                              title = "Mapa de Anomalias") {
  world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

  if (is.null(lon_range)) lon_range <- range(df_anom[[lon_col]], na.rm = TRUE) + c(-1, 1)
  if (is.null(lat_range)) lat_range <- range(df_anom[[lat_col]], na.rm = TRUE) + c(-1, 1)

  # Limita escala de cores para ±2 sigma
  lim <- 2

  ggplot2::ggplot(df_anom) +
    ggplot2::geom_raster(
      ggplot2::aes(x = .data[[lon_col]], y = .data[[lat_col]],
                   fill = pmin(pmax(anomaly_norm, -lim), lim)),
      interpolate = TRUE
    ) +
    ggplot2::scale_fill_gradientn(
      colors = rev(cmocean::cmocean("balance")(256)),
      limits = c(-lim, lim),
      name   = "Anomalia\n(σ)"
    ) +
    ggplot2::geom_sf(data = world, fill = "grey30", color = "grey50",
                     linewidth = 0.3, inherit.aes = FALSE) +
    ggplot2::coord_sf(xlim = lon_range, ylim = lat_range, expand = FALSE) +
    ggplot2::labs(title = title, x = "Longitude", y = "Latitude") +
    theme_ocean()
}

# ============================================================
# EXEMPLO
# ============================================================

# sst <- readRDS(file.path(path_processed, "sst_gridded.rds"))
#
# # Baseline 1993–2020
# clim <- compute_monthly_climatology(sst, var = "thetao",
#                                      baseline_years = 1993:2020)
# saveRDS(clim, file.path(path_processed, "sst_climatology.rds"))
#
# df_anom <- compute_anomalies(sst, clim, var = "thetao")
#
# p_cycle <- plot_seasonal_cycle(clim, var_label = "SST (°C)",
#                                 title = "Ciclo Sazonal da SST")
# p_map   <- plot_anomaly_map(df_anom,
#                              title = "Anomalias de SST (normalizado)")
#
# save_figure(p_cycle, "sst_seasonal_cycle")
# save_figure(p_map,   "sst_anomaly_map")
