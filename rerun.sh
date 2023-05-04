#!/bin/bash
#SBATCH --partition=celltypes
#SBATCH --mem=200g
#SBATCH --time=24:00:00

/usr/bin/time -v snakemake --cores 160 -s main.smk --latency-wait 60 --rerun-incomplete
