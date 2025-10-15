#!/bin/bash -l
#$ -S /bin/bash
#$ -l h_rt=24:0:0
#$ -l mem=2G
#$ -l tmpfs=4G
#$ -pe smp 8
#$ -t 1-100  # use this to submit a task array 
#$ -wd /home/uctpkbo/BH_replication

##$ -N testjob
##$ -o /home/uctpkbo/Scratch/HSR/test.log
##$ -m bea

module load stata
date
stata-mp -b process_scenarios_2016.do $SGE_TASK_ID
date