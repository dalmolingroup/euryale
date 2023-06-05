/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowEuryale.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.kaiju_db ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES
//
include { FASTX_COLLAPSER } from '../modules/local/fastx_toolkit/collapser'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { PREPROCESS } from '../subworkflows/local/preprocess'
include { HOST_REMOVAL } from '../subworkflows/local/host_removal'
include { TAXONOMY } from '../subworkflows/local/taxonomy'
include { ASSEMBLY } from '../subworkflows/local/assembly'
include { ALIGNMENT } from '../subworkflows/local/alignment'
include { FUNCTIONAL } from '../subworkflows/local/functional'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { GUNZIP } from '../modules/nf-core/gunzip/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow EURYALE {
    if (params.reference_fasta == null && params.diamond_db == null) { exit 1, 'A reference fasta (--reference_fasta) or a DIAMOND db (--diamond_db) must be specified' }

    ch_versions = Channel.empty()
    ch_kaiju_db = Channel.value([ [id: "kaiju_db"], file(params.kaiju_db)])
    ch_reference_fasta = params.reference_fasta ? file(params.reference_fasta) : []
    ch_diamond_db = params.diamond_db ? file(params.diamond_db) : []
    ch_id_mapping = params.id_mapping ? file(params.id_mapping) : []
    ch_host_reference = params.host_fasta ? Channel.value([ [id: "host_reference"], file(params.host_fasta)]) : false

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    INPUT_CHECK.out.reads.set { reads }

    PREPROCESS (
        reads
    )
    ch_versions = ch_versions.mix(PREPROCESS.out.versions)

    PREPROCESS.out.merged_reads
        .set { clean_reads }

    if (ch_host_reference) {
        HOST_REMOVAL (
            clean_reads,
            ch_host_reference
        )

        HOST_REMOVAL.out.unaligned_reads
            .set { clean_reads }
    }
    if (params.assembly_based) {
        ASSEMBLY (
            reads
        )
        ch_versions = ch_versions.mix(ASSEMBLY.out.versions)
    }

    GUNZIP (
        clean_reads
    )

    GUNZIP.out.gunzip
        .set { decompressed_reads }

    FASTX_COLLAPSER (
        decompressed_reads
    )

    ALIGNMENT (
        FASTX_COLLAPSER.out.collapsed,
        ch_reference_fasta,
        ch_diamond_db
    )
    ch_versions = ch_versions.mix(ALIGNMENT.out.versions)

    TAXONOMY (
        clean_reads,
        ch_kaiju_db
    )
    ch_versions = ch_versions.mix(TAXONOMY.out.versions)

    FUNCTIONAL (
        ch_id_mapping
    )


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowEuryale.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowEuryale.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(PREPROCESS.out.multiqc_files.collect())
    ch_multiqc_files = ch_multiqc_files.mix(TAXONOMY.out.kaiju_report.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ALIGNMENT.out.multiqc_files.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
