include { UNTAR } from '../../modules/nf-core/untar/main'
include { KAIJU_KAIJU } from '../../modules/nf-core/kaiju/kaiju/main'
include { KRAKEN2_KRAKEN2 } from '../../modules/nf-core/kraken2/kraken2/main'
include { KRAKENTOOLS_KREPORT2KRONA } from '../../modules/nf-core/krakentools/kreport2krona/main'
include { KAIJU_KAIJU2TABLE } from '../../modules/nf-core/kaiju/kaiju2table/main'
include { KAIJU_KAIJU2KRONA } from '../../modules/nf-core/kaiju/kaiju2krona/main'
include { KRONA_KTIMPORTTEXT } from '../../modules/nf-core/krona/ktimporttext/main'

include { MICROVIEW } from '../../modules/local/microview.nf'

workflow TAXONOMY {
    take:
    reads
    kaiju_db
    kraken2_db

    main:

    tax_report = Channel.empty()
    krona_input = Channel.empty()
    ch_versions = Channel.empty()

    if (params.run_kaiju) {
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

        tax_report = tax_report.mix(KAIJU_KAIJU2TABLE.out.summary)

        KAIJU_KAIJU2KRONA (kaiju_out, kaiju_db_files)
        krona_input = krona_input.mix(KAIJU_KAIJU2KRONA.out.txt)
        ch_versions = ch_versions.mix(KAIJU_KAIJU2KRONA.out.versions)
    }

    if (params.run_kraken2) {
        KRAKEN2_KRAKEN2 (
            reads,
            kraken2_db,
            false,
            false
        )
        tax_report = tax_report.mix(KRAKEN2_KRAKEN2.out.report)
        ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions.first())

        KRAKENTOOLS_KREPORT2KRONA (
            KRAKEN2_KRAKEN2.out.report
        )
        krona_input = krona_input.mix(KRAKENTOOLS_KREPORT2KRONA.out.txt)
        ch_versions = ch_versions.mix(KRAKENTOOLS_KREPORT2KRONA.out.versions.first())
    }


    if (!params.skip_microview) {
        MICROVIEW (
            tax_report.collect{it[1]}
        )
        ch_versions = ch_versions.mix(MICROVIEW.out.versions)
    }

    KRONA_KTIMPORTTEXT (krona_input)
    ch_versions = ch_versions.mix(KRONA_KTIMPORTTEXT.out.versions)

    KRONA_KTIMPORTTEXT.out.html.set { krona_report }

    emit:
    tax_report = tax_report
    krona_report = krona_report
    versions = ch_versions
}
