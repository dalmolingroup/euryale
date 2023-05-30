include { FASTQC as FASTQC_RAW;
          FASTQC as FASTQC_TRIMMED } from '../../modules/nf-core/fastqc/main'
include { FASTP } from '../../modules/nf-core/fastp/main'

workflow PREPROCESS {
    take:
    reads

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    FASTQC_RAW (
        reads
    )
    ch_versions = ch_versions.mix(FASTQC_RAW.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_RAW.out.zip.collect{it[1]}.ifEmpty([]))


    FASTP (
        reads,
        [],
        false,
        true
    )
    ch_versions = ch_versions.mix(FASTP.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]}.ifEmpty([]))

    FASTP.out.reads_merged
        .map { meta, path -> [[id: meta.id, single_end: true], path] }
        .set { merged_reads }


    FASTQC_TRIMMED (
        merged_reads
    )
    ch_versions = ch_versions.mix(FASTQC_TRIMMED.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip.collect{it[1]}.ifEmpty([]))

    emit:
    multiqc_files = ch_multiqc_files
    merged_reads = merged_reads
    versions = ch_versions
}
