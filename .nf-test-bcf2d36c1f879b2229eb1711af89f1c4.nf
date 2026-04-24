import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test process
include { LOCIDEX_CONCAT } from '/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/modules/local/locidex/concat/main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .addConverter(Path) { value -> value.toAbsolutePath().toString() } // Custom converter for Path. Only filename
        .build()

def jsonWorkflowOutput = new JsonGenerator.Options().excludeNulls().build()


workflow {

    // run dependencies
    

    // process mapping
    def input = []
    
                input[0] = Channel.of(
                    ["/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/tests/data/profiles/expected_merge_profile_1_of_2.tsv", "/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/tests/data/profiles/expected_merge_profile_2_of_2.tsv"])
                input[1] = Channel.of(
                    ["/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/tests/data/error_reports/MLST_error_report_1_of_2.tsv", "/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/tests/data/error_reports/MLST_error_report_2_of_2.tsv"])
                input[2] = Channel.of("ref")
                input[3] = input[0].flatten().count()
                
    //----

    //run process
    LOCIDEX_CONCAT(*input)

    if (LOCIDEX_CONCAT.output){

        // consumes all named output channels and stores items in a json file
        for (def name in LOCIDEX_CONCAT.out.getNames()) {
            serializeChannel(name, LOCIDEX_CONCAT.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = LOCIDEX_CONCAT.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
  
}

def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
}


workflow.onComplete {

    def result = [
        success: workflow.success,
        exitStatus: workflow.exitStatus,
        errorMessage: workflow.errorMessage,
        errorReport: workflow.errorReport
    ]
    new File("${params.nf_test_output}/workflow.json").text = jsonWorkflowOutput.toJson(result)
    
}
