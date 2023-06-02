include { DIAMOND_MAKEDB } from '../../modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTX } from '../../modules/nf-core/diamond/blastx/'

workflow ALIGNMENT {
    take:
    fasta
    reference_fasta
    diamond_db

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    if (!diamond_db) {
        DIAMOND_MAKEDB (
            reference_fasta
        )
        ch_versions = ch_versions.mix(DIAMOND_MAKEDB.out.versions)
        DIAMOND_MAKEDB.out.db.set { diamond_db }
    }

    def blast_columns = "qseqid sseqid pident slen qlen length mismatch gapopen qstart qend sstart send evalue bitscore full_qseq"
    DIAMOND_BLASTX (
        fasta,
        diamond_db,
        "txt",
        blast_columns
    )
    ch_versions = ch_versions.mix(DIAMOND_BLASTX.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(DIAMOND_BLASTX.out.log.collect{it[1]}.ifEmpty([]))

    emit:
    alignments = DIAMOND_BLASTX.out.txt
    multiqc_files = ch_multiqc_files
    versions = ch_versions
}
