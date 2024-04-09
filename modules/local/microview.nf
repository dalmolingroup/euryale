process MICROVIEW {
    tag 'report'
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://docker.io/jvfe/microview:v0.10.0':
        'docker.io/jvfe/microview:v0.10.0' }"

    input:
    path reports

    output:
    path "microview_report.html", emit: report
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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        MicroView: \$(microview --version | sed 's/.*version \\([0-9.]\\+\\).*/\\1/')
    END_VERSIONS
    """
}