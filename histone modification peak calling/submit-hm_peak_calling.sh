#!/bin/bash
#SBATCH -A kwcho_lab
#SBATCH -J jobsub_hm_peak_calling
#SBATCH -p standard
#SBATCH --time=10:00:00 ## total run time limit (HH:MM:SS)
#SBATCH --nodes=1 ##number of nodes to use
#SBATCH --cpus-per-task=20 ## number of cores to use per node
#SBATCH -o ./outputfiles/R-%x-%J.out ## Output file
#SBATCH -e ./errorfiles/R-%x-%J.err ## Error file

### SLURM JOB SUBMISSION SCRIPT
#       FILE_LIST = .txt file input, each line is a different /path/to/name.filetype
#       MACS2_INPUT = .sorted.bed input, to be used as macs2 input

FILE_LIST=/path/to/filelist.txt
MACS2_INPUT=/path/to/input.sorted.bed

# check if FILE_LIST exists (! -f) and is not empty (! -s)
if [ ! -f "$FILE_LIST" ] || [ ! -s "$FILE_LIST" ]; then
        echo "Error: FILE_LIST ($FILE_LIST) does not exist or is empty." >&2
        exit 1
fi

# check if MACS2_INPUT file exists
if [ ! -f "$MACS2_INPUT" ]; then
        echo "Error: MACS2_INPUT ($MACS2_INPUT) does not exist." >&2
        exit 1
fi

# submit a new job for every file in FILE_LIST
FILE_COUNT=$(wc -l < "$FILE_LIST")

# check if FILE_COUNT is greater than zero
if [ "$FILE_COUNT" -eq 0 ]; then
        echo "Error: No entries found in FILE_LIST." >&2
        exit 1
fi

echo "Submitting SLURM job array for $FILE_COUNT files..."

sbatch --array=1-$FILE_COUNT --export=FILE_LIST="$FILE_LIST",MACS2_INPUT="$MACS2_INPUT" "pipeline-hm_peak_calling.sh"
# NOTE: slurm job arrays start with index 1

echo "Jobs submitted for all files in FILE_LIST."
