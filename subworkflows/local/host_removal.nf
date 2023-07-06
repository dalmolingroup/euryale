include { BOWTIE2_BUILD } from '../../modules/nf-core/bowtie2/build/main'
include { BOWTIE2_ALIGN } from '../../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_SORT } from '../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_BAM2FQ } from '../../modules/nf-core/samtools/bam2fq/main'

include { SAMTOOLS_UNMAPPED_PAIRS } from '../../modules/local/samtools_unmapped'

workflow HOST_REMOVAL {
    take:
    reads
    host_genome

    main:

    ch_versions = Channel.empty()

    BOWTIE2_BUILD (
        host_genome
    )
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions)

    BOWTIE2_ALIGN (
        reads,
        BOWTIE2_BUILD.out.index,
        true,
        false
    )

    SAMTOOLS_UNMAPPED_PAIRS (
        BOWTIE2_ALIGN.out.bam
    )

    SAMTOOLS_SORT (
        SAMTOOLS_UNMAPPED_PAIRS.out.bam
    )

    SAMTOOLS_BAM2FQ (
        SAMTOOLS_SORT.out.bam,
        false
    )

    SAMTOOLS_BAM2FQ.out.reads
        .map {
            meta, path -> [[id: meta.id, single_end: true], path]
        }
        .set { final_reads }

    emit:
    versions = ch_versions
    unaligned_reads = final_reads
}
