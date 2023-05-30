 include { MEGAHIT } from '../../modules/nf-core/megahit/main'

workflow ASSEMBLY {
    take:
    reads

    main:

    ch_versions = Channel.empty()

    MEGAHIT (
        reads
    )
    ch_versions = ch_versions.mix(MEGAHIT.out.versions)

    emit:
    contigs = MEGAHIT.out.contigs
    versions = ch_versions
}
