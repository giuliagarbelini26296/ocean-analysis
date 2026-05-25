# 🌊 Ocean Physical Analysis

**Análise de dados de oceanografia física** — correntes, temperatura e salinidade oceânicas usando R.

## Sobre o Projeto

Este repositório reúne scripts, pipelines e visualizações para análise de propriedades físicas do oceano, com foco em:

- **Temperatura** da superfície e perfis verticais (SST, T-S diagrams)
- **Salinidade** e análise de massas d'água
- **Correntes oceânicas** — velocidade, direção e variabilidade
- **Estrutura termohalina** — termoclina, haloclina, picnoclina

## Estrutura do Repositório

```
ocean-analysis/
├── R/                        # Scripts de análise
│   ├── 01_data_ingestion.R   # Leitura e padronização de dados
│   ├── 02_qc_flags.R         # Controle de qualidade (QC)
│   ├── 03_ts_diagram.R       # Diagrama T-S e massas d'água
│   ├── 04_currents.R         # Análise de correntes (velocidade/direção)
│   ├── 05_climatology.R      # Climatologia e anomalias
│   └── utils.R               # Funções auxiliares
├── data/
│   ├── raw/                  # Dados brutos (não versionados — ver .gitignore)
│   └── processed/            # Dados processados e limpos
├── outputs/
│   ├── figures/              # Mapas, gráficos, diagramas
│   └── tables/               # Tabelas de estatísticas
├── docs/                     # Documentação, referências, notas de campo
├── .gitignore
├── ocean-analysis.Rproj      # RStudio project file
└── README.md
```

## Fontes de Dados Suportadas

| Fonte | Tipo de Dado | Formato |
|-------|-------------|---------|
| [Argo Floats](https://argo.ucsd.edu/) | T, S, perfis verticais | NetCDF |
| [HYCOM](https://www.hycom.org/) | Correntes, T, S (modelo) | NetCDF |
| [CMEMS / Copernicus](https://marine.copernicus.eu/) | SST, correntes, SSH | NetCDF / CSV |
| [WOD (NOAA)](https://www.ncei.noaa.gov/products/world-ocean-database) | Perfis históricos | CSV / NetCDF |
| CTD (campo) | T, S, pressão | CSV |

## Pacotes R Utilizados

```r
# Principais dependências
install.packages(c(
  "ncdf4",        # Leitura de arquivos NetCDF
  "oce",          # Oceanografia: CTD, T-S, marés
  "gsw",          # TEOS-10: equações de estado do mar
  "ggplot2",      # Visualizações
  "tidyverse",    # Manipulação de dados
  "patchwork",    # Composição de gráficos
  "rnaturalearth",# Mapas base
  "sf",           # Dados espaciais
  "lubridate",    # Manipulação de datas/séries temporais
  "cmocean"       # Paletas de cores oceanográficas
))
```

## Como Usar

```r
# 1. Clone o repositório
# git clone https://github.com/seu-usuario/ocean-analysis.git

# 2. Abra ocean-analysis.Rproj no RStudio

# 3. Instale as dependências
source("R/utils.R")
install_dependencies()

# 4. Coloque seus dados brutos em data/raw/

# 5. Execute o pipeline na ordem:
source("R/01_data_ingestion.R")
source("R/02_qc_flags.R")
source("R/03_ts_diagram.R")
```

## Convenções

- Coordenadas: longitude em [-180, 180], latitude em [-90, 90]
- Temperatura em **°C**, salinidade em **PSU (g/kg)**, pressão em **dbar**
- Padrão TEOS-10 para cálculos termodinâmicos (pacote `gsw`)
- Arquivos de saída nomeados como `YYYYMMDD_descricao.png`

## Licença

MIT License — livre para uso acadêmico e científico.

---
*Contribuições, issues e pull requests são bem-vindos!*
