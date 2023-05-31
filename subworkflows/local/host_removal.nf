include { BOWTIE2_BUILD } from '../../modules/nf-core/bowtie2/build/main'
include { BOWTIE2_ALIGN } from '../../modules/nf-core/bowtie2/align/main'

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

    emit:
    versions = ch_versions
    unaligned_reads = BOWTIE2_ALIGN.out.fastq
}
