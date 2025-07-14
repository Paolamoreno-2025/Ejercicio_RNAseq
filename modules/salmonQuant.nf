#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process salmonQuant {
    label 'process_high'
    tag { run }
    conda 'bioconda::salmon'

    input:
    tuple val(run), path(trimmed_reads), path(salmon_index)

    output:
    tuple val(run), path(run), emit: quant_dir

    script:
    if (trimmed_reads.size() == 2) {
        """
        echo "🚀 Salmon quant (Paired-End) for ${run}"
        salmon quant -i ${salmon_index} -l A \\
            -1 ${trimmed_reads[0]} \\
            -2 ${trimmed_reads[1]} \\
            -o ${run} \\
            --validateMappings
        """
    } else if (trimmed_reads.size() == 1) {
        """
        echo "🚀 Salmon quant (Single-End) for ${run}"
        salmon quant -i ${salmon_index} -l A \\
            -r ${trimmed_reads[0]} \\
            -o ${run} \\
            --validateMappings
        """
    } else {
        error "❌ Error: Unexpected number of reads (${trimmed_reads.size()}) for run: ${run}"
    }
}
