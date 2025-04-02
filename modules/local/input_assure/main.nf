process INPUT_ASSURE {
    tag "Assures Inputs are Consistent"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(mlst)

    output:
    tuple val(meta), path("${meta.id}.mlst.json.gz"),               emit: result
    tuple val(meta), path("*_error_report.csv"), optional: true,    emit: error_report
    path("versions.yml"),                                           emit: versions

    script:

    """
    input_assure.py \\
        --input ${mlst} \\
        --sample_id ${meta.id} \\
        --address ${meta.address} \\
        --output_error ${meta.id}_error_report.csv \\
        --output_json ${meta.id}.mlst.json.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
