#!/bin/bash
#SBATCH --job-name=array_simulated_ma   # Job name
#SBATCH --ntasks=1                  # Run a single task
#SBATCH --mem=2gb                   # Job Memory
#SBATCH --time=24:00:00             # Time limit hrs:min:sec
#SBATCH --output=array_%A-%a.log    # Standard output and error log
#SBATCH --array=1-100                # Array range

module load stata/mp_17
date
stata-mp -b process_scenarios_2016.do $SLURM_ARRAY_TASK_ID
date
