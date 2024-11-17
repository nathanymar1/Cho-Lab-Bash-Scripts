#!/bin/bash
#SBATCH -A kwcho_lab
#SBATCH -J hm_peak_calling
#SBATCH -p standard
#SBATCH --time=10:00:00 ## total run time limit (HH:MM:SS)
#SBATCH --nodes=1 ##number of nodes to use
#SBATCH --cpus-per-task=20 ## number of cores to use per node
#SBATCH -o ./outputfiles/R-%x-%J.out ## Output file
#SBATCH -e ./errorfiles/R-%x-%J.err ## Error file

# Exit immediately if a command exits with a non-zero status
set -e

module load bowtie2
module load samtools
module load bedtools2
module load macs
module load anaconda
module load deeptools

### Inputs: .sam
### Outputs: .sorted.bam, .bed, .narrowPeak

# Check if FILE_LIST is not empty
if [ ! -s "$FILE_LIST" ]; then
        echo "Error: FILE_LIST ($FILE_LIST) is empty or does not exist." >&2i
        exit 1
fi

# Check if MACS2_INPUT is not empty
if [ ! -s "$MACS2_INPUT" ]; then
        echo "Error: MACS2_INPUT ($MACS2_INPUT) is empty or does not exist." >&2
        exit 1
fi

# Extract .sam file for this SLURM array index
SAM=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$FILE_LIST")

# Check if SAM if not empty for this SLURM array inex
if [ ! -s "$SAM" ]; then
        echo "Error: No .sam file found for SLURM_ARRAY_TASK_ID ${SLURM_ARRAY_TASK_ID}." >&2
        exit 1
fi

# Extract directory and sample name
DIR_PATH=$(dirname "$SAM")
SAMPLE_NAME=$(basename "$SAM" .sam)

echo "Processing sample: $SAMPLE_NAME..."

# Step 1: Convert .sam to .sorted.bam
echo "Converting .sam to .sorted.bam..."
samtools view -b "$SAM" | \
        samtools sort -n | \
        samtools fixmate -m - - | \
        samtools sort - | \
        samtools markdup - "${DIR_PATH}/${SAMPLE_NAME}.sorted.bam"
if [ $? -ne 0 ]; then
        echo "Error: Failed to convert $SAM to .sorted.bam" >&2
        exit 1
fi
echo "Finished converting .sam to .sorted.bam"

# Step 2: Convert .sorted.bam to .sorted.bed
#       Note: .sorted.bam is sorted by read name, .sorted.bed is sorted by genomic coordinates
echo "Converting .sorted.bam to .sorted.bed..."
bedtools bamtobed -i "${DIR_PATH}/${SAMPLE_NAME}.sorted.bam" | \
        sort -k1,1 -k2,2n > "${DIR_PATH}/${SAMPLE_NAME}.sorted.bed"
if [ $? -ne 0 ]; then
        echo "Error: Failed to convert ${DIR_PATH}/${SAMPLE_NAME}.sorted.bam to .sorted.bed" >&2
        exit 1
fi
echo "Finished converting .sorted.bam to .sorted.bed"

# Step 3: Perform macs2 peak calling
echo "Performing macs2 peak calling..."
macs2 callpeak -t "${DIR_PATH}/${SAMPLE_NAME}.sorted.bed" \
        -c "$MACS2_INPUT" -f BED -g 1100000000 -n "${DIR_PATH}/${SAMPLE_NAME}" \
        -q 0.05 --broad --nomodel --shift 37 --extsize 73
if [ $? -ne 0 ]; then
        echo "Error: macs2 callpeak failed for sample $SAMPLE_NAME" >&2
        exit 1
fi
echo "Finished performing macs2 callpeak broad"

echo "Successfully processed sample: $SAMPLE_NAME"
