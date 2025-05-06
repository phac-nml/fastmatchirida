// Merge missing loci

process LOCIDEX_MERGE {
    tag 'Merge Profiles'
    label 'process_medium'
    fair true

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/locidex%3A0.3.0--pyhdfd78af_0' :
        'biocontainers/locidex:0.3.0--pyhdfd78af_0' }"


    input:
    path input_values // [file(sample1), file(sample2), file(sample3), etc...]
    val  input_tag    // makes output unique and denotes the item as the reference or query to prevent name collision
    val  merge_tsv

    output:
    path("${input_tag}/profile.tsv"),           emit: combined_profiles
    path("${input_tag}/MLST_error_report.csv"), emit: combined_error_report
    path "versions.yml",           emit: versions

    script:
    """
    locidex merge -i ${input_values.join(' ')} -o ${input_tag} -p ${merge_tsv}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex merge: \$(echo \$(locidex search -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
