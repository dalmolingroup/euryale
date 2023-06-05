process CREATE_DICTIONARY {
    label 'process_medium'

    conda "arthurvinx::medusaPipeline"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://jvfe/create-dictionary:v1.2':
        'docker.io/jvfe/create-dictionary:v1.2' }"

    input:
    path(id_mapping)

    output:
    path("NR2GO.txt"), emit: dictionary

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    awk -F "\\t" '{if((\$7!="") && (\$18!="")){print \$18"\\t"\$7}}' \\
        $id_mapping > genbank2GO.txt

    awk -F "\\t" '{if((\$4!="") && (\$7!="")){print \$4"\\t"\$7}}' \\
        $id_mapping > refseq2GO.txt

    createDictionary.R \\
        NR2GO.txt \\
        genbank2GO.txt \\
        refseq2GO.txt \\
        $task.cpus
    """
}
