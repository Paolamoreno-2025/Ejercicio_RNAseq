process salmonIndex {

    tag { index_name }

    input:
    tuple val(index_name), path(ref_transcriptome), path(ref_genome)

    output:
    path("salmon_index")  // ❌ no uses 'emit:' aquí

    conda 'bioconda::salmon'

    script:
    """
    mkdir -p salmon_index
    grep ">" ${ref_genome} | cut -f1 -d ' ' | sed 's/>//' > decoys.txt
    cat ${ref_transcriptome} ${ref_genome} | gzip > gentrome.fa.gz
    salmon index -t gentrome.fa.gz -i salmon_index --decoys decoys.txt
    """
}

