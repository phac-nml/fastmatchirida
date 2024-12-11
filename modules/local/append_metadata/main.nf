process APPEND_METADATA {
    tag "Appends metadata to distances"
    label 'process_single'

    input:
    val distances_path      // distance data as a TSV path
                            // this needs to be "val", because "path"
                            // won't stage the file correctly for exec
    val metadata_rows       // metadata rows (no headers) to be appened, list of lists
    val metadata_headers    // headers to name the metadata columns

    output:
    path("distances_and_metadata.tsv"), emit: distances

    exec:
    def distances_rows  // has a header row
    def metadata_rows_map = [:]
    def sample_names_map = [:] // maps sample names to Irida IDs
    def merged = []

    distances_path.withReader { reader ->
        distances_rows = reader.readLines()*.split('\t')
    }

    // Create a map of the metadata rows:
    // Start on i = 0 because there are no headers included.
    for(int i = 0; i < metadata_rows.size(); i++)
    {
        // "sample" -> ["sample", meta1, meta2, meta3, ...]
        sample_name = metadata_rows[i][0]
        metadata_rows_map[sample_name] = metadata_rows[i]

        // "sample" -> "Irida ID"
        sample_names_map[sample_name] = metadata_rows[i][1]
    }

    // Create the header row:
    merged.add(["Query ID", "Query Sample Name", "Reference ID", "Reference Sample Name", "Disance"]
                + metadata_headers[1..-1])

    // Merge the remaining rows in original order:
    // Start on i = 1 because we don't want the headers.
    for(int i = 1; i < distances_rows.size(); i++)
    {
        query_sample_name = distances_rows[i][0]
        query_irida_id = sample_names_map[query_sample_name]
        reference_sample_name = distances_rows[i][1]
        reference_irida_id = sample_names_map[reference_sample_name]
        distance = distances_rows[i][2]

        merged_row = [query_irida_id, query_sample_name, reference_irida_id, reference_sample_name, distance] \
                        + metadata_rows_map[reference_sample_name][2..-1]

        merged.add(merged_row)
    }

    task.workDir.resolve("distances_and_metadata.tsv").withWriter { writer ->
        merged.each { writer.writeLine it.join("\t") }
    }

}
