# We use this rather large base image for convenience as it matches the dev environment used to 
# create the BeerFestDB package and the Quarto reports. It includes R, RStudio, and many commonly used R packages.
FROM rocker/tidyverse:4.6.1

# Install BeerFestDB, its dependencies, and other packages used in the quarto reports.
WORKDIR /tmp
COPY BeerFestDB /tmp/BeerFestDB
RUN Rscript -e "install.packages(c('reshape2', 'DT', 'colorspace', 'ggrepel'))" \
    && Rscript -e "library(devtools); install('BeerFestDB', dependencies = TRUE, upgrade = FALSE)" \
    && rm -rf /tmp/BeerFestDB

WORKDIR /home/rstudio
