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
include { FASTX_COLLAPSER } from '../modules/nf-core/fastx/collapser'
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
    // Check mandatory parameters
    if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
    if (params.reference_fasta == null && params.diamond_db == null && params.skip_alignment == false) { exit 1, 'A reference fasta (--reference_fasta) or a DIAMOND db (--diamond_db) must be specified' }
    if (params.run_kaiju == true && params.kaiju_db == null && params.skip_classification == false) {exit 1, 'A Kaiju tar.gz database must be specified with --kaiju_db'}
    if (params.run_kraken2 == true && params.kraken2_db == null && params.skip_classification == false) {exit 1, 'A Kraken2 database must be specified with --kraken2_db'}
    if (params.id_mapping == null && params.skip_functional == false) {exit 1, 'An ID mapping file is necessary if you want to run functional annotation'}
    if (params.host_fasta == null && params.bowtie2_db == null && params.skip_host_removal == false) {exit 1, 'Either a host reference FASTA (--host_fasta) or a pre-built bowtie2 index (--bowtie2_db) must be specified'}

    ch_versions = Channel.empty()
    ch_kraken_db = params.run_kraken2 ? file(params.kraken2_db) : []
    ch_kaiju_db = params.run_kaiju ? Channel.value([ [id: "kaiju_db"], file(params.kaiju_db)]) : []
    ch_reference_fasta = params.reference_fasta ? file(params.reference_fasta) : []
    ch_diamond_db = params.diamond_db ? file(params.diamond_db) : []
    ch_bowtie2_db = params.bowtie2_db ? Channel.value([ [id: "host_db"], file(params.bowtie2_db)]) : []
    ch_id_mapping = params.id_mapping ? file(params.id_mapping) : []
    ch_host_reference = params.host_fasta ? Channel.value([ [id: "host_reference"], file(params.host_fasta)]) : false
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)
    INPUT_CHECK.out.reads.set { reads }

    if (params.skip_preprocess) {
        clean_reads = reads
    } else {
        PREPROCESS (
            reads
        )
        ch_versions = ch_versions.mix(PREPROCESS.out.versions)

        PREPROCESS.out.reads
            .set { clean_reads }
        ch_multiqc_files = ch_multiqc_files.mix(PREPROCESS.out.multiqc_files.collect())
    }

    if (!params.skip_host_removal) {
        if (ch_host_reference || ch_bowtie2_db) {
            HOST_REMOVAL (
                    clean_reads,
                    ch_host_reference,
                    ch_bowtie2_db
                    )

                HOST_REMOVAL.out.unaligned_reads
                .set { clean_reads }
        }
    }
    if (params.assembly_based) {
        ASSEMBLY (
            reads
        )

        ASSEMBLY.out.contigs
            .map { meta, path -> tuple([id: meta.id, single_end: true], path) }
            .set { clean_reads }

        ch_versions = ch_versions.mix(ASSEMBLY.out.versions)
    }

    if (!params.assembly_based && !params.skip_preprocess) {
        GUNZIP (
            clean_reads
        )

        GUNZIP.out.gunzip
            .set { decompressed_reads }

        FASTX_COLLAPSER (
            decompressed_reads
        )

        FASTX_COLLAPSER.out.fasta.set { clean_reads }
    }

     if (!params.skip_alignment) {
        ALIGNMENT (
            clean_reads,
            ch_reference_fasta,
            ch_diamond_db
        )
        ALIGNMENT.out.alignments.set{alignments}
        ch_versions = ch_versions.mix(ALIGNMENT.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(ALIGNMENT.out.multiqc_files.collect{it[1]}.ifEmpty([]))
    }

    if (!params.skip_classification) {
        TAXONOMY (
            clean_reads,
            ch_kaiju_db,
            ch_kraken_db
        )
        ch_versions = ch_versions.mix(TAXONOMY.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(TAXONOMY.out.tax_report.collect{it[1]}.ifEmpty([]))
    }

    if (!params.skip_functional && !params.skip_alignment) {
        FUNCTIONAL (
            alignments,
            ch_id_mapping
        )
    }

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

    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

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
