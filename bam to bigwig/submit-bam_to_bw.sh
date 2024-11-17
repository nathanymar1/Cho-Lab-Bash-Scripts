#!/bin/bash
#SBATCH -A kwcho_lab
#SBATCH -J jobsub_bam2bw
#SBATCH -p standard
#SBATCH --time=10:00:00 ## total run time limit (HH:MM:SS)
#SBATCH --nodes=1 ##number of nodes to use
#SBATCH --cpus-per-task=20 ## number of cores to use per node
#SBATCH -o ./outputfiles/R-%x-%J.out ## Output file
#SBATCH -e ./errorfiles/R-%x-%J.err ## Error file

### SLURM JOB SUBMISSION SCRIPT
#       FILE_LIST = .txt file input, each line is a different /path/to/name.filetype

# check if FILE_LIST exists (! -f) and is not empty (! -s)
if [ ! -f "$FILE_LIST" ] || [ ! -s "$FILE_LIST" ]; then
        echo "Error: FILE_LIST ($FILE_LIST) does not exist or is empty." >&2
        exit 1
fi

FILE_LIST=/path/to/filelist.txt

# submit a new job for every file in FILE_LIST
FILE_COUNT=$(wc -l < "$FILE_LIST")

# check if FILE_COUNT is greater than zero
if [ "$FILE_COUNT" -eq 0 ]; then
        echo "Error: No entries found in FILE_LIST." >&2
        exit 1
fi

echo "Submitting SLURM job array for $FILE_COUNT files..."
sbatch --array=1-$FILE_COUNT --export=FILE_LIST="$FILE_LIST" "pipeline-bam_to_bw.sh"
echo "Jobs submitted for all files in FILE_LIST."
