process COPY_FILE {
    tag 'Copy and Rename file'
    label "process_single"

    input:
    tuple val(meta), path(original_file), val(uniqueMLST)

    output:
    tuple val(meta), path("${meta.id}_${original_file}")

    script:
    """
    cp $original_file ${meta.id}_${original_file}
    """
}
