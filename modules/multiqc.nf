process multiqc {
    label 'process_low'
    conda 'bioconda::multiqc'

    input:
    path fastqc_dirs

    output:
    path "multiqc_report.html", emit: out

    script:
    def input_dirs = fastqc_dirs instanceof List ? fastqc_dirs.join(' ') : fastqc_dirs

    """
    multiqc ${input_dirs}
    """
}
