process bbduk {
    label 'process_medium'
    conda 'bioconda::bbmap'

    input:
    tuple val(run), path(fastq_reads)

    output:
    tuple val(run), path("trimmed_*")

    script:
    def scriptText = ''

    // DEBUG: mostrar tipo y contenido
    println "🧪 [DEBUG] bbduk recibio para ${run}: fastq_reads class=${fastq_reads.getClass()}"
    def readsList = fastq_reads instanceof List ? fastq_reads : [fastq_reads]
    println "🧪 [DEBUG] bbduk readsList tamaño: ${readsList.size()}"
    println "🧪 [DEBUG] bbduk readsList nombres: ${readsList*.getName()}"

    if (readsList.size() == 2) {
        def in1 = readsList[0].getName()
        def in2 = readsList[1].getName()
        def out1 = "trimmed_${in1}"
        def out2 = "trimmed_${in2}"

        scriptText = """
            echo "🔧 Running BBduk in Paired-End mode"
            bbduk.sh in1=${in1} in2=${in2} \\
                     out1=${out1} out2=${out2} \\
                     ref=adapters,artifacts ktrim=r k=23 mink=11 hdist=1 tpe tbo
        """
    } else if (readsList.size() == 1) {
        def in1 = readsList[0].getName()
        def out1 = "trimmed_${in1}"

        scriptText = """
            echo "🔧 Running BBduk en Single-End mode"
            bbduk.sh in=${in1} out=${out1} \\
                     ref=adapters,artifacts ktrim=r k=23 mink=11 hdist=1
        """
    } else {
        throw new IllegalArgumentException("❌ Error: Número inesperado de archivos FASTQ en bbduk: ${readsList.size()}")
    }

    return scriptText
}
