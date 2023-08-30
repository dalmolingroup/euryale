process ANNOTATE {
    label 'process_medium'

    conda "arthurvinx::medusaPipeline"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jvfe/annotate:v1.1':
        'docker.io/jvfe/annotate:v1.1' }"

    input:
    tuple val(meta), path(alignment)
    path(annotate_db)
    val minimum_pident
    val minimum_alen
    val minimum_bitscore
    val maximum_evalue

    output:
    tuple val(meta), path("*annotated.txt"), emit: annotated

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    annotate.py idmapping \\
        $alignment \\
        ${prefix}_annotated.txt \\
        NR2GO \\
        -l 1 \\
        --bitscore $minimum_bitscore \\
        --identity $minimum_pident \\
        --alen $minimum_alen \\
        --evalue $maximum_evalue \\
        --alenCol 3 \\
        --bitscoreCol 11 \\
        --evalueCol 10 \\
        -d $annotate_db
    """
}
