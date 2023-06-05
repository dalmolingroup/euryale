FROM r-base:4.3.0

LABEL image.author.name "jvfecav"

RUN Rscript -e "install.packages(c('dplyr', 'tidyr', 'data.table'))"

# Get Bioc Package
RUN Rscript -e "install.packages('BiocManager')"

RUN Rscript -e "BiocManager::install('GO.db')"

# Get ps
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

CMD ["bash"]

