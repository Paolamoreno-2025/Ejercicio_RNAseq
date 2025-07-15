process salmonIndex {

    tag { index_name }

    input:
    path(ref_genomeA)
    path(ref_genomeB)
    path(ref_transcriptomeA)
    path(ref_transcriptomeB)

    output:
    path("salmon_index")  // no uses 'emit:' aquí

    conda 'bioconda::salmon'

    script:
    """
    mkdir -p salmon_index
    grep ">" ${ref_genomeA}|cut -f1 -d' '|sed 's/>//' > decoys.txt
    grep ">" ${ref_genomeB}|cut -f1 -d' '|sed 's/>//' >> decoys.txt
    cat ${ref_transcriptomeA} ${ref_transcriptomeB} ${ref_genomeA} ${ref_genomeB} | gzip > gentrome.fa.gz
    salmon index -t gentrome.fa.gz -i salmon_index --decoys decoys.txt
    """
}

