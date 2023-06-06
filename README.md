## Introduction

**dalmolingroup/euryale** is a pipeline for taxonomic classification and functional annotation of metagenomic reads. Based on [MEDUSA](https://github.com/dalmolingroup/medusa).

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

## Pipeline summary

### Pre-processing

- Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
- Read trimming and merging ([`fastp`](https://github.com/OpenGene/fastp))
- (_optionally_) Host read removal ([`BowTie2`](https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml))
- Duplicated sequence removal ([`fastx collapser`](http://hannonlab.cshl.edu/fastx_toolkit/))
- Present QC and other data ([`MultiQC`](http://multiqc.info/))

### Assembly

- (_optionally_) Read assembly ([`MEGAHIT`](https://github.com/voutcn/megahit))

### Taxonomic classification

- Sequence classification ([`Kaiju`](https://github.com/bioinformatics-centre/kaiju/))
- Visualization ([`Krona`](https://github.com/marbl/Krona/wiki))

### Functional annotation

- Sequence alignment ([`DIAMOND`](https://github.com/bbuchfink/diamond))
- Map alignment matches to functional database ([`annotate`](https://github.com/dalmolingroup/annotate))

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.10.1`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Download the pipeline and test it on a minimal dataset with a single command:

   ```bash
   nextflow run dalmolingroup/euryale -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!

   ```bash
   nextflow run dalmolingroup/euryale --input samplesheet.csv --outdir <OUTDIR> --kaiju_db kaiju_reference --diamond_db diamond_db --reference_fasta diamond_fasta --host_fasta host_reference_fasta --id_mapping id_mapping_file -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>
   ```

## Credits

dalmolingroup/euryale was originally written by João Cavalcante.

We thank the following people for their extensive assistance in the development of this pipeline:

- Diego Morais (for developing the original [MEDUSA](https://github.com/dalmolingroup/medusa) pipeline)

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

> Morais DAA, Cavalcante JVF, Monteiro SS, Pasquali MAB and Dalmolin RJS (2022)
> MEDUSA: A Pipeline for Sensitive Taxonomic Classification and Flexible Functional Annotation
> of Metagenomic Shotgun Sequences.
> Front. Genet. 13:814437. doi: 10.3389/fgene.2022.814437

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
