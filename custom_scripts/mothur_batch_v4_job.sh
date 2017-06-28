#!/bin/bash
#SBATCH --job-name=mothur_batch_v4_script_run
#SBATCH --error=mothur_batch_v4_script_run.error
#SBATCH --time=12:00:00
#SBATCH --partition=ser-par-10g-2
#SBATCH --ntasks=16
mothur mothur_batch_v4_script.txt
