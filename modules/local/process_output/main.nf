process PROCESS_OUTPUT {
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.10' :
        'biocontainers/python:3.10' }"

    input:
    path(distances)

    output:
    path("results.csv"), emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    process_output.py \\
        $args \\
        --input $distances \\
        --output results.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        process_outout : 0.1.0
    END_VERSIONS
    """
}