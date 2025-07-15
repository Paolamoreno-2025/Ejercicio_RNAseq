#!/bin/bash
#$ -q all.q
#$ -V
#$ -cwd
#$ -pe smp 1
#$ -N EjercicioRNASeq_nextflow
#$ -S /bin/bash

# Activar Conda
source /home/jenny.paola/miniconda3/etc/profile.d/conda.sh
conda activate R2C

# Crear carpeta de salida si no existe
mkdir -p samples

# Descargar archivos JSON desde SRA si faltan o están vacíos
while IFS=, read -r run sample_name
do
  # Saltar la cabecera
  if [[ "$run" == "run" ]]; then
    continue
  fi

  json_file="samples/${run}.json"

  if [[ -s "$json_file" ]]; then
    echo "✅ El archivo $json_file ya existe y no está vacío, se omite la descarga."
  else
    echo "⬇️  Descargando JSON para: $run"
    ffq "$run" > "$json_file"

    # Validación: si falla o queda vacío, lo eliminamos
    if [[ $? -ne 0 || ! -s "$json_file" ]]; then
      echo "⚠️  Error: JSON descargado está vacío para $run. Eliminando archivo."
      rm -f "$json_file"
    else
      echo "✅ Descarga completa para $run"
    fi

    sleep 1
  fi
done < samples/samples.csv

# Ejecutar pipeline Nextflow
nextflow run /Storage/data1/jenny.paola/Ejercicio_RNAseq/workflows/main.nf \
  -c /Storage/data1/jenny.paola/Ejercicio_RNAseq/config/nextflow.config \
  --samples_csv /Storage/data1/jenny.paola/Ejercicio_RNAseq/samples/samples.csv \
  --ref_genomeA /Storage/data1/jenny.paola/Ejercicio_RNAseq/references/GCF_000208745.1_Criollo_cocoa_genome_V2_genomic.fix.fna \
  --ref_genomeB /Storage/data1/jenny.paola/Ejercicio_RNAseq/references/GCA_002911725.1_ASM291172v1_genomic.fix.fna \
  --ref_transcriptomeA /Storage/data1/jenny.paola/Ejercicio_RNAseq/references/GCF_000208745.1_Criollo_cocoa_genome_V2_rna_from_genomic.fix.fna \
  --ref_transcriptomeB /Storage/data1/jenny.paola/Ejercicio_RNAseq/references/GCA_002911725.1_ASM291172v1_rna_from_genomic.fix.fna \
  -profile process_medium_sge \
  -work-dir /Storage/data1/jenny.paola/Ejercicio_RNAseq/work \
  -resume
