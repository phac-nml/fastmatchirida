process COPY_FILE {
    tag 'Copy and Rename file'
    label "process_single"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu%3A20.04' :
    'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(original_file), val(uniqueMLST)

    output:
    tuple val(meta), path("${meta.id}_${original_file}")

    script:
    """
    cp $original_file ${meta.id}_${original_file}
    """
}
