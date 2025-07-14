process getReadFTP {
    label 'process_low'
    conda 'bioconda::ffq'
    input:
    val run

    output:
    tuple val(run), path("${run}.json")

    maxForks 1

    """
    ffq -o ${run}.json ${run}
    """
}
