process CREATE_DB {
    label 'process_high'

    conda "arthurvinx::medusaPipeline"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jvfe/annotate:v1.1':
        'docker.io/jvfe/annotate:v1.1' }"

    input:
    path(dictionary)

    output:
    path("annotate_db"), emit: db

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir annotate_db

    annotate.py createdb \\
        $dictionary \\
        NR2GO \\
        0 \\
        1 \\
        -d annotate_db
    """
}
