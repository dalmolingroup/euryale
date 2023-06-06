include { GUNZIP } from '../../modules/nf-core/gunzip/main'
include { CREATE_DICTIONARY } from '../../modules/local/create_dictionary'
include { CREATE_DB } from '../../modules/local/annotate/createdb'

workflow FUNCTIONAL {
    take:
    id_mapping_file

    main:

    ch_mapping_file = Channel.value([ [id: "id_mapping"], id_mapping_file])
    ch_versions = Channel.empty()

    GUNZIP (
        ch_mapping_file
    )
    GUNZIP.out.gunzip.map { id, path -> path }.set { decompressed_mapping }

    CREATE_DICTIONARY (
        decompressed_mapping
    )

    CREATE_DB (
        CREATE_DICTIONARY.out.dictionary
    )

    emit:
    versions = ch_versions
}
