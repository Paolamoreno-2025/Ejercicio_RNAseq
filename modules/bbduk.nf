process bbduk {
    label 'process_high'
    conda 'bioconda::bbmap'

    input:
    tuple val(run), path(fastq_reads)

    output:
    tuple val(run), path("trimmed_*"), emit: bbduk_output
    path "bbduk_${run}.log", emit: bbduk_log
    path "bbduk_${run}_stats.tsv", emit: bbduk_stats
 
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
                     t=8 \\
                     out1=${out1} out2=${out2} \\
                     qtrim=r trimq=20 \\
                     mlf=0.75 \\
                     ref=adapters,artifacts ktrim=r k=23 mink=11 hdist=1 tpe tbo 2> bbduk_${run}.log
            awk '
            BEGIN {
                OFS="\t"
                print "run", "in_reads", "in_bases", "k_reads", "k_bases",
                      "q_reads", "q_bases",
                      "tr_reads", "tr_bases", "final_reads", "final_bases"
              }
            /Input:/          { inR=\$2; inB=\$4 }
            /KTrimmed:/       { kR=\$2; kB=\$5 }
            /QTrimmed:/       { qR=\$2; qB=\$5 }
            /Total Removed:/  { tr=\$3; tb=\$6 }
            /Result:/         { rR=\$2; rB=\$5 }
            END {
              print "${run}\\t"inR"\\t"inB"\\t"kR"\\t"kB"\\t"tr"\\t"tb"\\t"rR"\\t"rB"\\t"qR"\\t"qB
            }
        ' bbduk_${run}.log > bbduk_${run}_stats.tsv
        """
    } else if (readsList.size() == 1) {
        def in1 = readsList[0].getName()
        def out1 = "trimmed_${in1}"

        scriptText = """
            echo "🔧 Running BBduk en Single-End mode"
            bbduk.sh in=${in1} out=${out1} \\
                     t=8 \\
                     qtrim=r trimq=20 \\
                     mlf=0.75 \\
                     ref=adapters,artifacts ktrim=r k=23 mink=11 hdist=1 2> bbduk_${run}.log
            awk '
            BEGIN {
                OFS="\t"
                print "run", "in_reads", "in_bases", "k_reads", "k_bases",
                      "q_reads", "q_bases",
                      "tr_reads", "tr_bases", "final_reads", "final_bases"
              }
            /Input:/          { inR=\$2; inB=\$4 }
            /KTrimmed:/       { kR=\$2; kB=\$5 }
            /QTrimmed:/       { qR=\$2; qB=\$5 }
            /Total Removed:/  { tr=\$3; tb=\$6 }
            /Result:/         { rR=\$2; rB=\$5 }
            END {
              print "${run}\\t"inR"\\t"inB"\\t"kR"\\t"kB"\\t"tr"\\t"tb"\\t"rR"\\t"rB"\\t"qR"\\t"qB
            }
        ' bbduk_${run}.log > bbduk_${run}_stats.tsv
        """
    } else {
        throw new IllegalArgumentException("❌ Error: Número inesperado de archivos FASTQ en bbduk: ${readsList.size()}")
    }

    return scriptText
}
