process multiqc_trimmed {
    label 'process_medium_sge'
    conda 'bioconda::multiqc'

    input:
    tuple val(run), path(fastqc_reports)

    output:
    path "multiqc_report_trimmed.html", emit: out

    script:
    def reportDirs = fastqc_reports instanceof List ? fastqc_reports.join(' ') : fastqc_reports

    """
    multiqc ${reportDirs} --filename multiqc_report_trimmed.html
    """
}
