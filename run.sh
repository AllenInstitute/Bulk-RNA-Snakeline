#!/bin/bash
#SBATCH --partition=celltypes
#SBATCH --mem=480g
#SBATCH --time=72:00:00
#SBATCH --exclusive
#SBATCH --nodes=2

/usr/bin/time -v snakemake --cores 176 -s main.smk --latency-wait 60
