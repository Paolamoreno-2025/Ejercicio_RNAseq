process fastqc {
    label 'process_medium_sge'
    conda 'bioconda::fastqc'

    input:
    tuple val(run), path(fastq_read_list)

    output:
    tuple val(run), path("${run}_fastqc"), emit: out

    script:
    def outDir = "${run}_fastqc"

    """
    mkdir -p ${outDir}
    fastqc -o ${outDir} ${fastq_read_list.join(' ')}
    """
}
