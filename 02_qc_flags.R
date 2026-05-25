# 02_qc_flags.R — Controle de qualidade (QC) de dados oceânicos
# ==============================================================
# Baseado nos critérios do Argo QC Manual e IOC/UNESCO

source("R/utils.R")
load_dependencies()

# ============================================================
# FLAGS QC (padrão Argo/IODE)
# 0 = não verificado | 1 = bom | 2 = provavelmente bom
# 3 = provavelmente ruim | 4 = ruim | 9 = ausente
# ============================================================

QC_GOOD          <- 1L
QC_PROBABLY_GOOD <- 2L
QC_PROBABLY_BAD  <- 3L
QC_BAD           <- 4L
QC_MISSING       <- 9L

# ============================================================
# 1. RANGE CHECK — limites físicos globais
# ============================================================

range_check <- function(df) {
  df <- dplyr::mutate(df,
    qc_temp = dplyr::case_when(
      is.na(temp)              ~ QC_MISSING,
      temp < -2.5 | temp > 40  ~ QC_BAD,
      temp < -2   | temp > 35  ~ QC_PROBABLY_BAD,
      TRUE                     ~ QC_GOOD
    ),
    qc_psal = dplyr::case_when(
      is.na(psal)              ~ QC_MISSING,
      psal < 2    | psal > 41  ~ QC_BAD,
      psal < 5    | psal > 40  ~ QC_PROBABLY_BAD,
      TRUE                     ~ QC_GOOD
    ),
    qc_pres = dplyr::case_when(
      is.na(pres)             ~ QC_MISSING,
      pres < 0    | pres > 6000 ~ QC_BAD,
      TRUE                    ~ QC_GOOD
    )
  )
  return(df)
}

# ============================================================
# 2. SPIKE TEST — detecção de spikes individuais
# ============================================================

spike_test <- function(x, threshold = 2.0) {
  n      <- length(x)
  spikes <- rep(FALSE, n)
  for (i in 2:(n - 1)) {
    if (is.na(x[i - 1]) | is.na(x[i]) | is.na(x[i + 1])) next
    ref    <- (x[i - 1] + x[i + 1]) / 2
    spikes[i] <- abs(x[i] - ref) > threshold
  }
  return(spikes)
}

apply_spike_test <- function(df, temp_thresh = 2.0, psal_thresh = 0.5) {
  df <- dplyr::mutate(df,
    spike_temp = spike_test(temp, temp_thresh),
    spike_psal = spike_test(psal, psal_thresh),
    qc_temp    = dplyr::if_else(spike_temp & qc_temp == QC_GOOD,
                                QC_PROBABLY_BAD, qc_temp),
    qc_psal    = dplyr::if_else(spike_psal & qc_psal == QC_GOOD,
                                QC_PROBABLY_BAD, qc_psal)
  )
  return(df)
}

# ============================================================
# 3. GRADIENT TEST — variação excessiva com profundidade
# ============================================================

gradient_test <- function(df, temp_grad = 9.0, psal_grad = 1.5) {
  df <- dplyr::arrange(df, pres)
  df <- dplyr::mutate(df,
    d_temp = abs(temp - dplyr::lag(temp)),
    d_psal = abs(psal - dplyr::lag(psal)),
    qc_temp = dplyr::if_else(!is.na(d_temp) & d_temp > temp_grad,
                              QC_PROBABLY_BAD, qc_temp),
    qc_psal = dplyr::if_else(!is.na(d_psal) & d_psal > psal_grad,
                              QC_PROBABLY_BAD, qc_psal)
  )
  return(df)
}

# ============================================================
# 4. DENSITY INVERSION CHECK
# ============================================================

density_inversion_check <- function(df, threshold = -0.03) {
  df <- dplyr::arrange(df, pres)
  df <- dplyr::mutate(df,
    d_sigma = sigma0 - dplyr::lag(sigma0),
    density_inversion = !is.na(d_sigma) & d_sigma < threshold
  )
  n_inv <- sum(df$density_inversion, na.rm = TRUE)
  if (n_inv > 0) message("  ⚠ ", n_inv, " inversões de densidade detectadas.")
  return(df)
}

# ============================================================
# 5. PIPELINE COMPLETO DE QC
# ============================================================

run_qc <- function(df) {
  message("Iniciando QC...")

  df <- range_check(df)
  message("  ✓ Range check")

  df <- apply_spike_test(df)
  message("  ✓ Spike test")

  df <- gradient_test(df)
  message("  ✓ Gradient test")

  df <- density_inversion_check(df)
  message("  ✓ Density inversion check")

  # Resumo
  n_bad_t <- sum(df$qc_temp %in% c(QC_BAD, QC_PROBABLY_BAD), na.rm = TRUE)
  n_bad_s <- sum(df$qc_psal %in% c(QC_BAD, QC_PROBABLY_BAD), na.rm = TRUE)
  message("QC completo. Temp suspeita: ", n_bad_t,
          " | Sal suspeita: ", n_bad_s, " de ", nrow(df), " obs.")

  # Filtra apenas dados bons/provavelmente bons para análise
  df_clean <- dplyr::filter(df,
    qc_temp %in% c(QC_GOOD, QC_PROBABLY_GOOD),
    qc_psal %in% c(QC_GOOD, QC_PROBABLY_GOOD)
  )

  return(list(full = df, clean = df_clean))
}

# ============================================================
# EXEMPLO
# ============================================================

# argo <- readRDS(file.path(path_processed, "argo_profiles.rds"))
# qc_result <- run_qc(argo)
# df_clean  <- qc_result$clean
# saveRDS(df_clean, file.path(path_processed, "argo_qc_clean.rds"))
