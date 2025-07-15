process downloadReadFTP {

    label 'process_low'
    conda 'bioconda::python'  // Entorno con Python disponible

    input:
    tuple val(run), path(json_file)

    output:
    tuple val(run), path("${run}.fastq.gz")

    script:
    """

    python /Storage/data1/jenny.paola/Ejercicio_RNAseq/bin/download_from_json.py --json ${json_file} --output ${run}.fastq.gz
    """
}
