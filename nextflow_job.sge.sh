#!/bin/bash
#$ -cwd
#$ -V
#$ -N nextflow_job
#$ -pe smp 4
#$ -o /Storage/data1/jenny.paola/R2C/logs/nextflow_job.o$JOB_ID
#$ -e /Storage/data1/jenny.paola/R2C/logs/nextflow_job.e$JOB_ID
#$ -S /bin/bash

WORKDIR="/Storage/data1/jenny.paola/R2C"
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate R2C

module load nextflow

cd "$WORKDIR"

nextflow run workflows/main.nf \
  -c workflows/sge.config \
  --samples_csv "$WORKDIR/samples/samples.csv" \
  --ref_genomeA "$WORKDIR/references/GCF_000208745.1_Criollo_cocoa_genome_V2_genomic.fix.fna" \
  --ref_genomeB "$WORKDIR/references/GCA_002911725.1_ASM291172v1_genomic.fix.fna" \
  --ref_transcriptomeA "$WORKDIR/references/GCF_000208745.1_Criollo_cocoa_genome_V2_rna_from_genomic.fix.fna" \
  --ref_transcriptomeB "$WORKDIR/references/GCA_002911725.1_ASM291172v1_rna_from_genomic.fix.fna" \
  -profile process_medium \
  -work-dir "$WORKDIR/work" \
  -resume
