/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowEuryale.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES
//

include { DOWNLOAD as DOWNLOAD_FUNCTIONAL_DB } from '../modules/local/download/main'
include { DOWNLOAD as DOWNLOAD_FUNCTIONAL_DICT } from '../modules/local/download/main'
include { DOWNLOAD as DOWNLOAD_KAIJU } from '../modules/local/download/main'
include { DOWNLOAD as DOWNLOAD_KRAKEN } from '../modules/local/download/main'
include { DOWNLOAD as DOWNLOAD_HOST } from '../modules/local/download/main'

workflow DOWNLOAD {
    if (params.download_functional) {
        DOWNLOAD_FUNCTIONAL_DB("reference_fasta.fa.gz", params.functional_db)
        DOWNLOAD_FUNCTIONAL_DICT("id_mapping.tab.gz", params.functional_dictionary)
    }

    if (params.download_kaiju) {
        DOWNLOAD_KAIJU("kaiju_db.tar.gz", params.kaiju_db_url)
    }

    if (params.download_kraken) {
        DOWNLOAD_KRAKEN("kraken2_db.tar.gz", params.kraken2_db_url)
    }

    if (params.download_host) {
        DOWNLOAD_HOST("host_fasta.fa.gz", params.host_url)
    }
}
