process LOCIDEX_CONCAT {
    tag 'Concat LOCIDEX files'
    label 'process_medium'

    conda "bioconda::csvtk=0.30.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.30.0--h9ee0642_0' :
        'biocontainers/csvtk:0.30.0--h9ee0642_0' }"

    input:
    path(input_profile, stageAs: "?/*") // [profiles1.tsv, profiles2.tsv, ..., profilesn.tsv]
    path(input_error,   stageAs: "?/*") // [error_report1.csv, error_report2.csv, ... , error_reportn.csv]
    val input_tag                       // makes output unique and denotes the item as the reference or query to prevent name collision
    val input_count

    output:
    path("*.tsv"),       emit: combined_profiles
    path("*.csv"),       emit: combined_error_report
    path "versions.yml", emit: versions

    script:
    combined_dir = "concat_${input_tag}"

    """
    if ((${input_count} > 1)); then
        # Concatenate the profile results
        csvtk  \\
            concat -t \\
            --num-cpus $task.cpus \\
            ${input_profile.join(' ')} \\
            -o profile_${combined_dir}.tsv
        #
        csvtk  \\
        concat \\
            --num-cpus $task.cpus \\
            ${input_error.join(' ')} \\
            -o MLST_error_report_${combined_dir}.csv
    else
        mv "${input_profile}" profile_${combined_dir}.tsv
        mv "${input_error}" MLST_error_report_${combined_dir}.csv
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """

    }
