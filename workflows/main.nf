#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { downloadReadFTP     } from '../modules/downloadReadFTP.nf'
include { bbduk               } from '../modules/bbduk.nf'
include { fastqc              } from '../modules/fastqc.nf'
include { multiqc             } from '../modules/multiqc.nf'
include { fastqc_trimmed      } from '../modules/fastqc_trimmed.nf'
include { multiqc_trimmed     } from '../modules/multiqc_trimmed.nf'
include { salmonQuant         } from '../modules/salmonQuant.nf'
include { sampleInfo          } from '../modules/sampleInfo.nf'
include { salmonIndex         } from '../modules/salmonIndex.nf'

workflow {

    // Leer CSV de muestras y obtener run y sample_name
    samples_ch = Channel
        .fromPath(params.samples_csv)
        .splitCsv(header: true)
        .map { row -> tuple(row.run, row.sample_name) }

    // Generar tuplas (run, path al archivo JSON)
    download_inputs_ch = samples_ch
        .map { run, sample_name ->
            def json_path = file("samples/${run}.json")
            if (!json_path.exists()) {
                error "No existe archivo JSON para run ${run}: ${json_path}"
            }
            tuple(run, json_path)
        }

    // Ejecutar proceso de descarga
    reads_ch = downloadReadFTP(download_inputs_ch)

    // FastQC en lecturas sin recorte, por muestra
    fastqc_raw_ch = fastqc(reads_ch)

    // Extraer directorios FastQC para MultiQC global
    fastqc_dirs_ch = fastqc_raw_ch.map { run, fastqc_dir -> fastqc_dir }

    // Esperar a recolectar todos los directorios FastQC en una lista para MultiQC global
    multiqc_raw_ch = multiqc(fastqc_dirs_ch.collect())

    // BBDuk y FastQC en lecturas recortadas (single-end y futuro paired-end)
    trimmed_ch = reads_ch
        .map { run, fq ->
            def fq_list = fq instanceof List ? fq : [fq]
            tuple(run, fq_list)
        }
        .view { "📦 bbduk INPUT: ${it[0]} -> ${it[1]*.getName()}" }
        | bbduk

    bbduk_output = trimmed_ch.map { run, files ->
       def file_list = files instanceof List ? files : [files]
       tuple(run, file_list)
    }
    fastqc_trimmed_ch = fastqc_trimmed(bbduk_output)

    // Extraer dirs FastQC trimmed para MultiQC trimmed global
    fastqc_trimmed_dirs_ch = fastqc_trimmed_ch.map { run, fastqc_dir -> fastqc_dir }
    multiqc_trimmed_ch = multiqc_trimmed(fastqc_trimmed_dirs_ch.collect())

    // Construcción de índices de referencia para Salmon
    salmon_index_ch = salmonIndex(params.ref_genomeA,params.ref_genomeB,params.ref_transcriptomeA,params.ref_transcriptomeB)
    salmonIndex.out.view{ "salmonIndex: $it" }

    // Salmon cuantificación usando trimmed reads + índice
    salmon_quant_ch = bbduk_output.combine(salmon_index_ch) | salmonQuant
    salmonQuant.out.view{ "salmonQuant: $it" }

    // Generación de información de muestras
    sample_info_ch = sampleInfo(download_inputs_ch)

    // Visualización de progreso
    fastqc_raw_ch.view { "✅ FastQC raw reads completado para run: ${it[0]}" }
    multiqc_raw_ch.view { "📊 MultiQC global report generado para raw reads" }
    fastqc_trimmed_ch.view { "✅ FastQC trimmed reads completado para run: ${it[0]}" }
    multiqc_trimmed_ch.view { "📊 MultiQC global report generado para trimmed reads" }
    salmon_quant_ch.view { "✅ Salmon quant completado para run: ${it[0]}" }
    sample_info_ch.view { "📁 Sample info generado para run: ${it[0]}" }
}

