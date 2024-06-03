process DOWNLOAD {
    tag "$id"

    label 'process_single'
    label 'error_retry_delay'

    input:
    val id
    val url

    output:
    path "${prefix}", emit: db

    script:
    prefix = task.ext.prefix ?: "${id}"

    """
    wget -O ${prefix} $url
    """

    stub:
    """
    touch ${prefix}
    """
}
