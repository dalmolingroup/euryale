include { UNTAR } from '../../modules/nf-core/untar/main'
include { KAIJU_KAIJU } from '../../modules/nf-core/kaiju/kaiju/main'
include { KAIJU_KAIJU2TABLE } from '../../modules/nf-core/kaiju/kaiju2table/main'
include { KAIJU_KAIJU2KRONA } from '../../modules/nf-core/kaiju/kaiju2krona/main'
include { KRONA_KTIMPORTTEXT } from '../../modules/nf-core/krona/ktimporttext/main'

workflow TAXONOMY {
    take:
    reads
    kaiju_db

    main:

    ch_versions = Channel.empty()

    UNTAR ( kaiju_db )
    ch_versions = ch_versions.mix(UNTAR.out.versions)

    UNTAR.out.untar.map{ meta, path -> path }.set { kaiju_db_files }

    KAIJU_KAIJU (reads, kaiju_db_files)
    ch_versions = ch_versions.mix(KAIJU_KAIJU.out.versions)

    KAIJU_KAIJU.out.results.set { kaiju_out }

    KAIJU_KAIJU2TABLE (
        kaiju_out,
        kaiju_db_files,
        "species"
    )

    KAIJU_KAIJU2TABLE.out.summary.set { kaiju_report }

    KAIJU_KAIJU2KRONA (kaiju_out, kaiju_db_files)
    ch_versions = ch_versions.mix(KAIJU_KAIJU2KRONA.out.versions)

    KRONA_KTIMPORTTEXT (KAIJU_KAIJU2KRONA.out.txt)
    ch_versions = ch_versions.mix(KRONA_KTIMPORTTEXT.out.versions)

    KRONA_KTIMPORTTEXT.out.html.set { krona_report }

    emit:
    kaiju_report = kaiju_report
    krona_report = krona_report
    versions = ch_versions
}
