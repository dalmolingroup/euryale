process ANNOTATE {
    label 'process_medium'

    conda "arthurvinx::medusaPipeline"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jvfe/annotate:v1.1':
        'docker.io/jvfe/annotate:v1.1' }"

    input:
    tuple val(meta), path(alignment)
    path(annotate_db)

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
        -d $annotate_db
    """
}
