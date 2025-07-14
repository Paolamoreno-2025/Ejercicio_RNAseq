process sampleInfo {
    label 'process_low'
    conda 'bioconda::jq'

    input:
    tuple val(run), path(json_file)

    // Suponiendo que el script genera un archivo llamado sample_info_${run}.txt
    output:
    tuple val(run), file("sample_info_${run}.txt")

    script:
    """
    ${projectDir}/../bin/sampleinfo.sh ${json_file} > sample_info_${run}.txt
    """
}
