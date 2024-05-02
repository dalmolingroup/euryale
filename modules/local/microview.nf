process MICROVIEW {
    tag 'report'
    label 'process_low'

    conda "bioconda::microview=0.10.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://docker.io/jvfe/microview:v0.11.0':
        'docker.io/jvfe/microview:v0.11.0' }"

    input:
    path reports

    output:
    path "microview_report.html", emit: report
    path "microview_tables"     , emit: tables
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    microview \\
        --taxonomy . \\
        --output microview_report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        MicroView: \$(microview --version | sed 's/.*version \\([0-9.]\\+\\).*/\\1/')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch microview_report.html
    mkdir microview_tables

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        MicroView: \$(microview --version | sed 's/.*version \\([0-9.]\\+\\).*/\\1/')
    END_VERSIONS
    """
}
