# 01_data_ingestion.R — Leitura e padronização de dados oceânicos
# =================================================================
# Suporte: Argo floats (NetCDF), CTD em CSV, HYCOM/CMEMS (NetCDF)

source("R/utils.R")
load_dependencies()
create_dirs()

# ============================================================
# 1. LEITURA DE PERFIL ARGO (NetCDF)
# ============================================================

read_argo_profile <- function(nc_file) {
  nc <- ncdf4::nc_open(nc_file)
  on.exit(ncdf4::nc_close(nc))

  df <- tibble::tibble(
    lon      = as.vector(ncdf4::ncvar_get(nc, "LONGITUDE")),
    lat      = as.vector(ncdf4::ncvar_get(nc, "LATITUDE")),
    date     = as.Date(as.vector(ncdf4::ncvar_get(nc, "JULD")),
                       origin = "1950-01-01"),
    cycle    = as.vector(ncdf4::ncvar_get(nc, "CYCLE_NUMBER")),
    pres     = as.vector(ncdf4::ncvar_get(nc, "PRES")),
    temp     = as.vector(ncdf4::ncvar_get(nc, "TEMP")),
    psal     = as.vector(ncdf4::ncvar_get(nc, "PSAL"))
  )

  # Filtra valores fill (_FillValue = 99999)
  df <- dplyr::filter(df, temp < 99990, psal < 99990, pres < 99990)

  # Converte para TEOS-10
  df <- dplyr::mutate(df,
    SA = sp_to_sa(psal, pres, lon, lat),
    CT = t_to_ct(SA, temp, pres),
    sigma0 = calc_sigma_theta(SA, CT)
  )

  message("Argo: ", nrow(df), " observações carregadas de ", basename(nc_file))
  return(df)
}

# ============================================================
# 2. LEITURA DE CTD EM CSV
# ============================================================

read_ctd_csv <- function(csv_file, lon_col = "lon", lat_col = "lat",
                          t_col = "temperature", s_col = "salinity",
                          p_col = "pressure") {
  df <- readr::read_csv(csv_file, show_col_types = FALSE)

  # Renomeia para nomes padrão do projeto
  df <- dplyr::rename(df,
    lon  = !!lon_col,
    lat  = !!lat_col,
    temp = !!t_col,
    psal = !!s_col,
    pres = !!p_col
  )

  # TEOS-10
  df <- dplyr::mutate(df,
    SA     = sp_to_sa(psal, pres, lon, lat),
    CT     = t_to_ct(SA, temp, pres),
    sigma0 = calc_sigma_theta(SA, CT)
  )

  message("CTD CSV: ", nrow(df), " registros carregados de ", basename(csv_file))
  return(df)
}

# ============================================================
# 3. LEITURA DE CAMPO ESCALAR NetCDF (SST, SSH, etc.)
# ============================================================

read_scalar_netcdf <- function(nc_file, var_name, lon_name = "lon",
                                lat_name = "lat", time_name = "time") {
  nc <- ncdf4::nc_open(nc_file)
  on.exit(ncdf4::nc_close(nc))

  lon  <- ncdf4::ncvar_get(nc, lon_name)
  lat  <- ncdf4::ncvar_get(nc, lat_name)
  time_raw <- ncdf4::ncvar_get(nc, time_name)

  # Tenta detectar unidade de tempo
  time_units <- ncdf4::ncatt_get(nc, time_name, "units")$value
  origin <- sub(".* since ", "", time_units)
  dates  <- as.Date(time_raw, origin = origin)

  data   <- ncdf4::ncvar_get(nc, var_name)
  fill   <- ncdf4::ncatt_get(nc, var_name, "_FillValue")$value

  # Expande para data frame longo (lon x lat x time)
  grid <- expand.grid(lon = lon, lat = lat, time_idx = seq_along(dates))
  grid$date  <- dates[grid$time_idx]
  grid$value <- as.vector(data)
  grid$value[grid$value == fill] <- NA
  grid$time_idx <- NULL

  names(grid)[names(grid) == "value"] <- var_name

  message(var_name, ": ", nrow(grid), " células carregadas de ", basename(nc_file))
  return(tibble::as_tibble(grid))
}

# ============================================================
# 4. EXEMPLO DE USO (descomente para testar)
# ============================================================

# argo <- read_argo_profile("data/raw/argo_example.nc")
# ctd  <- read_ctd_csv("data/raw/ctd_station01.csv")
# sst  <- read_scalar_netcdf("data/raw/sst_cmems.nc", var_name = "thetao")

# Salva dados processados
# saveRDS(argo, file.path(path_processed, "argo_profiles.rds"))
# saveRDS(sst,  file.path(path_processed, "sst_gridded.rds"))
