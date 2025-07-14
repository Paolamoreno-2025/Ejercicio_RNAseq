process salmonQuantMerge {
    label 'process_medium'
    conda 'bioconda::salmon'  // Verificar versión de Salmon >= 1.5.0

    input:
    // Espera una lista de paths (directorio de cuantificación)
    path quant_dirs from quant_dirs_ch

    output:
    path "expression_matrix.tsv"

    script:
    // Convertir la lista de paths en una cadena separada por espacios
    def quant_paths = quant_dirs.collect { it.toString() }.join(' ')

    """
    salmon quantmerge \
        --quants ${quant_paths} \
        --output expression_matrix.tsv \
        --column TPM
    """
}
