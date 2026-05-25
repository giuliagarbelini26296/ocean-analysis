# 🌊 Ocean Physical Analysis

**Análise de dados de oceanografia física** — correntes, temperatura e salinidade oceânicas usando R.

<img width="1620" height="1260" alt="image" src="https://github.com/user-attachments/assets/7c0cb426-20e9-4f51-8746-1eaad250dd64" />


---

## Visualizações de Exemplo

| Correntes Superficiais | Anomalia de SST |
|---|---|
<img width="1980" height="1260" alt="image" src="https://github.com/user-attachments/assets/dba66476-2fcc-4321-8c64-b446312a9386" />
<img width="1980" height="1170" alt="image" src="https://github.com/user-attachments/assets/1ec09a7a-d0a9-433b-92e2-6cabda7ea9ce" />


### Perfis Verticais de T e S

<img width="1800" height="1440" alt="image" src="https://github.com/user-attachments/assets/3ea259d8-4625-45bd-9f86-603a5a7c66f6" />


---

## Sobre o Projeto

Este repositório reúne scripts, pipelines e visualizações para análise de propriedades físicas do oceano, com foco em:

- **Temperatura** da superfície e perfis verticais (SST, diagramas T-S)
- **Salinidade** e identificação de massas d'água
- **Correntes oceânicas** — velocidade, direção e variabilidade
- **Estrutura termohalina** — termoclina, haloclina, picnoclina

---

## Estrutura do Repositório

```
ocean-analysis/
├── R/
│   ├── utils.R               # Funções auxiliares e tema ggplot
│   ├── 01_data_ingestion.R   # Leitura de NetCDF (Argo, CMEMS) e CSV (CTD)
│   ├── 02_qc_flags.R         # Controle de qualidade padrão Argo/IODE
│   ├── 03_ts_diagram.R       # Diagrama T-S, isopicnais e massas d'água
│   ├── 04_currents.R         # Mapa de correntes, rosa, EKE, séries temporais
│   ├── 05_climatology.R      # Climatologia mensal e anomalias
│   └── ocean_plots.R         # Visualizações de exemplo (dados sintéticos)
├── outputs/
│   └── figures/              # Figuras geradas pelos scripts
├── data/
│   ├── raw/                  # Dados brutos (não versionados)
│   └── processed/            # Dados processados
├── docs/
├── .gitignore
├── ocean-analysis.Rproj
└── README.md
```

---

## Fontes de Dados Suportadas

| Fonte | Tipo de Dado | Formato |
|-------|-------------|---------|
| [Argo Floats](https://argo.ucsd.edu/) | T, S, perfis verticais | NetCDF |
| [HYCOM](https://www.hycom.org/) | Correntes, T, S (modelo) | NetCDF |
| [CMEMS / Copernicus](https://marine.copernicus.eu/) | SST, correntes, SSH | NetCDF / CSV |
| [WOD (NOAA)](https://www.ncei.noaa.gov/products/world-ocean-database) | Perfis históricos | CSV / NetCDF |
| CTD (campo) | T, S, pressão | CSV |

---

## Pacotes R Utilizados

```r
install.packages(c(
  "ggplot2",           # Visualizações
  "dplyr", "tidyr",    # Manipulação de dados
  "patchwork",         # Composição de gráficos
  "metR",              # Contornos e campos meteorológicos/oceanográficos
  "ggnewscale",        # Múltiplas escalas de cor no ggplot2
  "rnaturalearth",     # Mapas base
  "rnaturalearthdata", # Dados de países
  "sf",                # Dados espaciais
  "scales",            # Formatação de escalas
  "ncdf4",             # Leitura de arquivos NetCDF
  "oce",               # Oceanografia: CTD, T-S, marés
  "gsw",               # TEOS-10: equações de estado do mar
  "lubridate"          # Séries temporais
))
```

---

## Como Usar

```r
# 1. Clone o repositório
# git clone https://github.com/giuliagarbelini26296/ocean-analysis.git

# 2. Abra ocean-analysis.Rproj no RStudio

# 3. Gere as visualizações de exemplo
source("R/ocean_plots.R")

# 4. Para análise com dados reais, execute na ordem:
source("R/01_data_ingestion.R")
source("R/02_qc_flags.R")
source("R/03_ts_diagram.R")
source("R/04_currents.R")
source("R/05_climatology.R")
```

---

## Convenções

- Coordenadas: longitude em [-180, 180], latitude em [-90, 90]
- Temperatura em **°C**, salinidade em **PSU (g/kg)**, pressão em **dbar**
- Padrão **TEOS-10** para cálculos termodinâmicos (pacote `gsw`)
- Arquivos de saída nomeados como `YYYYMMDD_descricao.png`

---

## Licença

MIT License — livre para uso acadêmico e científico.

---

*Contribuições, issues e pull requests são bem-vindos!*
