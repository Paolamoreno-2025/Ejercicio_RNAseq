process fastqc_trimmed {
    label 'process_medium_sge'
    conda 'bioconda::fastqc'

    input:
    tuple val(run), path(trimmed_reads)

    output:
    tuple val(run), path("fastqc_trimmed_${run}"), emit: out

    script:
    def outDir = "fastqc_trimmed_${run}"

    """
    mkdir -p ${outDir}
    fastqc -o ${outDir} ${trimmed_reads.join(' ')}
    """
}
