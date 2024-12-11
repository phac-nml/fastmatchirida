process APPEND_METADATA {
    tag "append_metadata"
    label 'process_single'

    input:
    val distances_path       // cluster data as a TSV path
                            // this needs to be "val", because "path"
                            // won't stage the file correctly for exec
    val metadata_rows       // metadata rows (no headers) to be appened, list of lists
    val metadata_headers    // headers to name the metadata columns

    output:
    path("distances_and_metadata.tsv"), emit: distances

    exec:
    def distances_rows  // has a header row
    def metadata_rows_map = [:]
    def merged = []

    distances_path.withReader { reader ->
        distances_rows = reader.readLines()*.split('\t')
    }

    // Create a map of the metadata rows:
    // Start on i = 0 because there are no headers included.
    for(int i = 0; i < metadata_rows.size(); i++)
    {
        // "sample" -> ["sample", meta1, meta2, meta3, ...]
        metadata_rows_map[metadata_rows[i][0]] = metadata_rows[i]
    }

    // Merge the headers
    merged.add(distances_rows[0] + metadata_headers)

    // Merge the remaining rows in original order:
    // Start on i = 1 because we don't want the headers.
    for(int i = 1; i < distances_rows.size(); i++)
    {
        def sample_key = distances_rows[i][1] // We want ref ID (second column)
        merged.add(distances_rows[i] + metadata_rows_map[sample_key][1..-1])
    }

    task.workDir.resolve("distances_and_metadata.tsv").withWriter { writer ->
        merged.each { writer.writeLine it.join("\t") }
    }

}
