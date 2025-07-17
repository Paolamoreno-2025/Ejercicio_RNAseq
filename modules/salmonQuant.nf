#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process salmonQuant {
    label 'process_high'
    //tag { run }
    conda 'bioconda::salmon'

    input:
    tuple val(run), path(trimmed_reads), path(salmon_index)

    output:
    tuple( val(run), path("${run}"), emit: 'quant_dir')

   
    script:

    def reads_list =
            trimmed_reads instanceof List ? trimmed_reads :
            trimmed_reads.isDirectory() ? trimmed_reads.iterator().toList().sort() :
            [ trimmed_reads ]

    if (reads_list.size() == 2) {
        """
        echo "🚀 Salmon quant (Paired-End) for ${run}"
        salmon quant -i ${salmon_index} -l A \\
            --threads 8 \\
            -1 ${trimmed_reads[0]} \\
            -2 ${trimmed_reads[1]} \\
            -o ${run} \\
            --validateMappings
        """
    } else if (reads_list.size() == 1) {
        """
        echo "🚀 Salmon quant (Single-End) for ${run}"
        salmon quant -i ${salmon_index} -l A \\
            --threads 8 \\
            -r ${trimmed_reads[0]} \\
            -o ${run} \\
            --validateMappings
        """
    } else {
        error "❌ Error: Unexpected number of reads (${trimmed_reads.size()}) for run: ${run}"
    }
}
