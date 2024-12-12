// Merge missing loci

process LOCIDEX_MERGE {
    tag 'Merge Profiles'
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    "docker.io/mwells14/locidex:0.2.3" :
    task.ext.override_configured_container_registry != false ? 'docker.io/mwells14/locidex:0.2.3' :
    'mwells14/locidex:0.2.3' }"

    input:
    path input_query // [file(sample1), file(sample2), file(sample3), etc...]
    path input_reference // [file(sample1), file(sample2), file(sample3), etc...]

    output:
    path("${combined_dir1}/*.tsv"), emit: combined_profiles_query
    path("${combined_dir2}/*.tsv"), emit: combined_profiles_reference
    path "versions.yml", emit: versions

    script:
    combined_dir1 = "merged_query"
    combined_dir2 = "merged_reference"
    """
    locidex merge -i ${input_query.join(' ')} -o ${combined_dir1}
    mv ${combined_dir1}/profile.tsv ${combined_dir1}/profile_query.tsv
    locidex merge -i ${input_reference.join(' ')} -o ${combined_dir2}
    mv ${combined_dir2}/profile.tsv ${combined_dir2}/profile_reference.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex merge: \$(echo \$(locidex search -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
