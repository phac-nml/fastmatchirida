process PROCESS_OUTPUT {
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:2.2.1' :
        'biocontainers/pandas:2.2.1' }"

    input:
    path distances
    val threshold

    output:
    path "results.tsv", emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    process_output.py \\
        $args \\
        --input $distances \\
        --output results.tsv \\
        --threshold $threshold

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        process_outout : 0.1.0
    END_VERSIONS
    """
}
