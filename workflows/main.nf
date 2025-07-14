#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { downloadReadFTP     } from '../modules/downloadReadFTP.nf'
include { bbduk               } from '../modules/bbduk.nf'
include { fastqc              } from '../modules/fastqc.nf'
include { multiqc             } from '../modules/multiqc.nf'
include { fastqc_trimmed      } from '../modules/fastqc_trimmed.nf'
include { multiqc_trimmed     } from '../modules/multiqc_trimmed.nf'
include { salmonQuant as salmonQuantA } from '../modules/salmonQuant.nf'
include { salmonQuant as salmonQuantB } from '../modules/salmonQuant.nf'
include { sampleInfo          } from '../modules/sampleInfo.nf'
include { salmonIndex as salmonIndexA } from '../modules/salmonIndex.nf'
include { salmonIndex as salmonIndexB } from '../modules/salmonIndex.nf'

params.samples_csv         = params.samples_csv         ?: "samples/samples.csv"
params.ref_transcriptomeA  = params.ref_transcriptomeA  ?: "/Storage/data1/jenny.paola/R2C/references/GCA_002911725.1_ASM291172v1_rna_from_genomic.fix.fna"
params.ref_genomeA         = params.ref_genomeA         ?: "/Storage/data1/jenny.paola/R2C/references/GCA_002911725.1_ASM291172v1_genomic.fix.fna"
params.ref_transcriptomeB  = params.ref_transcriptomeB  ?: "/Storage/data1/jenny.paola/R2C/references/GCF_000208745.1_Criollo_cocoa_genome_V2_rna_from_genomic.fix.fna"
params.ref_genomeB         = params.ref_genomeB         ?: "/Storage/data1/jenny.paola/R2C/references/GCF_000208745.1_Criollo_cocoa_genome_V2_genomic.fix.fna"

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
                error "❌ No existe archivo JSON para run ${run}: ${json_path}"
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

    fastqc_trimmed_ch = fastqc_trimmed(trimmed_ch)

    // Extraer dirs FastQC trimmed para MultiQC trimmed global
    fastqc_trimmed_dirs_ch = fastqc_trimmed_ch.map { run, fastqc_dir -> fastqc_dir }
    multiqc_trimmed_ch = multiqc_trimmed(fastqc_trimmed_dirs_ch.collect())

    // Construcción de índices de referencia para Salmon
    salmon_indexA_ch = Channel.of(tuple("indexA", file(params.ref_transcriptomeA), file(params.ref_genomeA)))
    salmon_indexB_ch = Channel.of(tuple("indexB", file(params.ref_transcriptomeB), file(params.ref_genomeB)))

    indexA_result_ch = salmonIndexA(salmon_indexA_ch)
    indexB_result_ch = salmonIndexB(salmon_indexB_ch)

    // Salmon cuantificación usando trimmed reads + índice
    salmon_quantA_ch = trimmed_ch.combine(indexA_result_ch)
        .map { trimmed, index -> tuple(trimmed[0], trimmed[1], index) }
        | salmonQuantA

    salmon_quantB_ch = trimmed_ch.combine(indexB_result_ch)
        .map { trimmed, index -> tuple(trimmed[0], trimmed[1], index) }
        | salmonQuantB

    // Generación de información de muestras
    sample_info_ch = sampleInfo(download_inputs_ch)

    // Visualización de progreso
    fastqc_raw_ch.view { "✅ FastQC raw reads completado para run: ${it[0]}" }
    multiqc_raw_ch.view { "📊 MultiQC global report generado para raw reads" }
    fastqc_trimmed_ch.view { "✅ FastQC trimmed reads completado para run: ${it[0]}" }
    multiqc_trimmed_ch.view { "📊 MultiQC global report generado para trimmed reads" }
    salmon_quantA_ch.view { "✅ Salmon quant A completado para run: ${it[0]}" }
    salmon_quantB_ch.view { "✅ Salmon quant B completado para run: ${it[0]}" }
    sample_info_ch.view { "📁 Sample info generado para run: ${it[0]}" }
}

