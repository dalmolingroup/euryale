process FASTX_COLLAPSER {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::fastx_toolkit=0.0.14"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastx_toolkit:0.0.14--hdbdd923_11':
        'quay.io/biocontainers/fastx_toolkit:0.0.14--hdbdd923_11' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("*fasta"), emit: collapsed
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fastx_collapser \\
        -i $fastq \\
        -o ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(fastx_collapser -h) | sed -nE 's/.*([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/p' ))
    END_VERSIONS
    """
}
