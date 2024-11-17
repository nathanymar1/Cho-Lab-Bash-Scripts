#!/bin/bash
#SBATCH -A kwcho_lab
#SBATCH -J bam2bw
#SBATCH -p standard
#SBATCH --nodes=1 ##number of nodes to use
#SBATCH --cpus-per-task=20 ##number of cores to use per node
#SBATCH -o ./outputfiles/R-%x-%J.out ##Output file
#SBATCH -e ./errorfiles/R-%x-%J.err ##Error file

module load deeptools
module load samtools

# Exit if FILE_LIST is empty
if [ ! -s "$FILE_LIST" ]; then
        echo "Error: FILE_LIST ($FILE_LIST) is empty or does not exist." >&2i
        exit 1
fi

# Extract .bam file for this SLURM array index
BAM_FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$FILE_LIST")

# Check if BAM_FILE if not empty for this SLURM array inex
if [ ! -s "$BAM_FILE" ]; then
        echo "Error: No .sam file found for SLURM_ARRAY_TASK_ID ${SLURM_ARRAY_TASK_ID}." >&2
        exit 1
fi

# Extract directory and BAM file name
DIR_PATH=$(dirname "$BAM_FILE")
SAMPLE_NAME=$(basename "$BAM_FILE" .bam)

echo "Processing sample ($SAMPLE_NAME)..."

# Step 1: Index the BAM file
echo "Indexing BAM file."
samtools index "$BAM_FILE" "${DIR_PATH}/${SAMPLE_NAME}.bai"

# Step 2: Run bamCoverage on current BAM_FILE
echo "Converting .bam to .bw"
bamCoverage -b "$BAM_FILE" -o "${DIR_PATH}/${SAMPLE_NAME}.bw" \
        --effectiveGenomeSize 1100000000 \
        --binSize 50 \
        --normalizeUsing RPKM

echo "Finished processing sample $SAMPLE_NAME"
