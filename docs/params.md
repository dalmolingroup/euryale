# dalmolingroup/euryale pipeline parameters

A pipeline for metagenomic taxonomic classification and functional annotation. Based on MEDUSA.

## Input/output options

Define where the pipeline should find input data and save output data.

| Parameter       | Description                                                                                                                                                                                                                                                                                                                                                                                  | Type      | Default | Required | Hidden |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ------- | -------- | ------ |
| `input`         | Path to comma-separated file containing information about the samples in the experiment. <details><summary>Help</summary><small>You will need to create a design file with information about the samples in your experiment before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row.</small></details> | `string`  |         | True     |        |
| `outdir`        | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure.                                                                                                                                                                                                                                                                     | `string`  |         | True     |        |
| `email`         | Email address for completion summary. <details><summary>Help</summary><small>Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.</small></details>                                  | `string`  |         |          |        |
| `multiqc_title` | MultiQC report title. Printed as page header, used for filename if not otherwise specified.                                                                                                                                                                                                                                                                                                  | `string`  |         |          |        |
| `save_dbs`      | Save DIAMOND db to results directory after construction                                                                                                                                                                                                                                                                                                                                      | `boolean` |         |          |        |

## Decontamination

| Parameter    | Description | Type     | Default | Required | Hidden |
| ------------ | ----------- | -------- | ------- | -------- | ------ |
| `host_fasta` |             | `string` | None    |          |        |

## Alignment

| Parameter         | Description                   | Type     | Default | Required | Hidden |
| ----------------- | ----------------------------- | -------- | ------- | -------- | ------ |
| `reference_fasta` | Path to FASTA genome file.    | `string` | None    |          |        |
| `diamond_db`      | Path to pre-built DIAMOND db. | `string` | None    |          |        |

## Taxonomy

| Parameter  | Description | Type     | Default | Required | Hidden |
| ---------- | ----------- | -------- | ------- | -------- | ------ |
| `kaiju_db` |             | `string` | None    | True     |        |

## Functional

| Parameter          | Description                                                      | Type      | Default | Required | Hidden |
| ------------------ | ---------------------------------------------------------------- | --------- | ------- | -------- | ------ |
| `id_mapping`       | Path to ID mapping file to be used for the Functional annotation | `string`  | None    | True     |        |
| `minimum_bitscore` | Minimum bitscore of a match to be used for annotation            | `integer` | 50      |          |        |
| `minimum_pident`   | Minimum identity of a match to be used for annotation            | `integer` | 80      |          |        |
| `minimum_alen`     | Minimum alignment length of a match to be used for annotation    | `integer` | 50      |          |        |
| `maximum_evalue`   | Maximum evalue of a match to be used for annotation              | `number`  | 0.0001  |          |        |

## Assembly

| Parameter        | Description | Type      | Default | Required | Hidden |
| ---------------- | ----------- | --------- | ------- | -------- | ------ |
| `assembly_based` |             | `boolean` |         |          |        |

## Max job request options

Set the top limit for requested resources for any single job.

| Parameter    | Description                                                                                                                                                                                                                                                                 | Type      | Default | Required | Hidden |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ------- | -------- | ------ |
| `max_cpus`   | Maximum number of CPUs that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the CPU requirement for each process. Should be an integer e.g. `--max_cpus 1`</small></details>                                      | `integer` | 16      |          | True   |
| `max_memory` | Maximum amount of memory that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the memory requirement for each process. Should be a string in the format integer-unit e.g. `--max_memory '8.GB'`</small></details> | `string`  | 128.GB  |          | True   |
| `max_time`   | Maximum amount of time that can be requested for any single job. <details><summary>Help</summary><small>Use to set an upper-limit for the time requirement for each process. Should be a string in the format integer-unit e.g. `--max_time '2.h'`</small></details>        | `string`  | 240.h   |          | True   |

## Generic options

Less common options for the pipeline, typically set in a config file.

| Parameter                     | Description                                                                                                                                                                                                                                                                                                                                                                                                  | Type      | Default                        | Required | Hidden |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | ------------------------------ | -------- | ------ |
| `help`                        | Display help text.                                                                                                                                                                                                                                                                                                                                                                                           | `boolean` |                                |          | True   |
| `version`                     | Display version and exit.                                                                                                                                                                                                                                                                                                                                                                                    | `boolean` |                                |          | True   |
| `publish_dir_mode`            | Method used to save pipeline results to output directory. <details><summary>Help</summary><small>The Nextflow `publishDir` option specifies which intermediate files should be saved to the output directory. This option tells the pipeline what method should be used to move these files. See [Nextflow docs](https://www.nextflow.io/docs/latest/process.html#publishdir) for details.</small></details> | `string`  | copy                           |          | True   |
| `email_on_fail`               | Email address for completion summary, only when pipeline fails. <details><summary>Help</summary><small>An email address to send a summary email to when the pipeline is completed - ONLY sent if the pipeline does not exit successfully.</small></details>                                                                                                                                                  | `string`  |                                |          | True   |
| `plaintext_email`             | Send plain-text email instead of HTML.                                                                                                                                                                                                                                                                                                                                                                       | `boolean` |                                |          | True   |
| `max_multiqc_email_size`      | File size limit when attaching MultiQC reports to summary emails.                                                                                                                                                                                                                                                                                                                                            | `string`  | 25.MB                          |          | True   |
| `monochrome_logs`             | Do not use coloured log outputs.                                                                                                                                                                                                                                                                                                                                                                             | `boolean` |                                |          | True   |
| `hook_url`                    | Incoming hook URL for messaging service <details><summary>Help</summary><small>Incoming hook URL for messaging service. Currently, MS Teams and Slack are supported.</small></details>                                                                                                                                                                                                                       | `string`  |                                |          | True   |
| `multiqc_config`              | Custom config file to supply to MultiQC.                                                                                                                                                                                                                                                                                                                                                                     | `string`  |                                |          | True   |
| `multiqc_logo`                | Custom logo file to supply to MultiQC. File name must also be set in the MultiQC config file                                                                                                                                                                                                                                                                                                                 | `string`  |                                |          | True   |
| `multiqc_methods_description` | Custom MultiQC yaml file containing HTML including a methods description.                                                                                                                                                                                                                                                                                                                                    | `string`  |                                |          |        |
| `tracedir`                    | Directory to keep pipeline Nextflow logs and reports.                                                                                                                                                                                                                                                                                                                                                        | `string`  | ${params.outdir}/pipeline_info |          | True   |
| `validate_params`             | Boolean whether to validate parameters against the schema at runtime                                                                                                                                                                                                                                                                                                                                         | `boolean` | True                           |          | True   |
| `show_hidden_params`          | Show all params when using `--help` <details><summary>Help</summary><small>By default, parameters set as _hidden_ in the schema are not shown on the command line when a user runs with `--help`. Specifying this option will tell the pipeline to show all parameters.</small></details>                                                                                                                    | `boolean` |                                |          | True   |
