// Merge missing loci

process LOCIDEX_MERGE {
    tag 'Merge Profiles'
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    "docker.io/mwells14/locidex:0.2.3" :
    task.ext.override_configured_container_registry != false ? 'docker.io/mwells14/locidex:0.2.3' :
    'mwells14/locidex:0.2.3' }"

    input:
    path input_values // [file(sample1), file(sample2), file(sample3), etc...]
    val combined_dir
    val query_ref

    output:
    path("${combined_dir}/*.tsv"), emit: combined_profiles
    path "versions.yml", emit: versions

    script:
    """
    locidex merge -i ${input_values.join(' ')} -o ${combined_dir}
    mv ${combined_dir}/profile.tsv ${combined_dir}/profile_${query_ref}.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex merge: \$(echo \$(locidex search -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
