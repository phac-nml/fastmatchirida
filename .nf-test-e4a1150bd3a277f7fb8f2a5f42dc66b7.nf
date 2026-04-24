import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test process
include { PROFILE_DISTS } from '/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/modules/local/profile_dists/main.nf'

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
                    ["/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/tests/data/profiles/input-profile-data_mixed_ids_missing_loci.tsv"])
                input[1] = Channel.of(
                    ["/home/CSCScience.ca/ssutcliffe/1_pipelinetesting/fastmatchirida/tests/data/profiles/input-profile-data_mixed_ids_missing_loci-ref.tsv"])
                input[2] = Channel.of("matrix")
                input[3] = []
                input[4] = []
                
    //----

    //run process
    PROFILE_DISTS(*input)

    if (PROFILE_DISTS.output){

        // consumes all named output channels and stores items in a json file
        for (def name in PROFILE_DISTS.out.getNames()) {
            serializeChannel(name, PROFILE_DISTS.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = PROFILE_DISTS.out as Object[]
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
