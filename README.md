Bulk-RNA-Snakeline
=================================================
![cover](Image/RNA-SEQ.png)

## Motivation
Due to the rapid advancements in sequencing technology, researchers are now able to generate massive amounts of biological data through an increased number of samples and more affordable options. This has led to a growing demand for simple, efficient methods to process and analyze large datasets, ultimately transforming them into meaningful and reproducible information. Workflow engines offer a valuable solution to this challenge, as they streamline and automate processing tasks, thus reducing the risk of user bias and errors that may arise from manual procedures.

Recognizing the need to adapt to the ever-increasing volume of data inputs and the constant evolution of processing software, the Bioinformatics Core team at the Allen Institute (BiCore) has begun transitioning towards automated workflows. In particular, they are employing Snakemake, a powerful workflow engine, to facilitate the quality assessment, trimming, and mapping of Bulk RNA-Sequencing (RNA-Seq) data. By embracing automated workflows, the BiCore team aims to improve efficiency, consistency, and reproducibility in their research, ultimately enhancing the overall quality of their findings.

Table of Contents
-----------------
* [Quickstart-Guide](#Quickstart-Guide)
* [Required Tools](#Required-Tools)
* [About-Snakeline](#About-Bulk-RNA-Snakeline)
* [Authors and history](#authors-and-history)
* [Pipeline Overview](#Pipeline-Overview)
* [Directory Structure](#Directory-Structure)
* [Acknowledgments](#acknowledgments)
* [References](#references)

## Quickstart Guide
Follow these steps to use the Bulk-RNA-Snakeline:
1. Download the repository (.zip), move it to your working directory, and unzip it
2. Create and load Conda environment with all dependencies:
    ```bash
    conda env create --name snakeline_env -f envs/Bulk-RNA-Snakeline.yml 
    ```
3. Activate the Conda environment:
    ```bash
    conda activate snakeline_env
    ```
4. Move RAW Fastq Files into `Bulk-RNA-Snakeline` folder.
5. Prepare the pipeline by creating directory structure:
    ```bash
    python3 setup.py
    ```
    Or if `sample_list.txt` is supplied:
    ```bash
    python3 setup.py -s <name_of_sample_file>
    ```
6. Adjust parameters in `config.yml`:
    ```bash
    nano config/config.yml
    ```
7. Execute snakemake and run the workflow:
    ```bash
    snakemake --cores 12 -s <snakefile>
    ```
    Or using Slurm (optional):
    ```bash
    srun --partition=celltypes --mem=60g --time=24:00:00 snakemake --cores 160 -s main.smk
    ```
    ```bash
    sbatch run.sh
    ```
8. Troubleshooting common errors:

    - A raised LockException:
        ```bash
        rm .snakemake/locks/*
        ```
    - Directory cannot be locked:
        ```bash
        snakemake -s main.smk --unlock
        ```
    - Incomplete Run:
        ```bash
        srun --partition=celltypes --mem=60g --time=24:00:00 snakemake --cores 160 -s main.smk --latency-wait 60 --rerun-incomplete
        ```
        ```bash
        sbatch rerun.sh
        ```

> **Note:** This pipeline will take a long time depending on the data and number of cores available.

## Required Tools  

 * [FastQC 0.11.9](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) (A quality control tool for high throughput sequence data)

 * [CutAdapt 4.1](https://journal.embnet.org/index.php/embnetjournal/article/view/200/0) (Automates quality  control and adapter trimming of fastq files)

 * [STAR v2.7.1a](https://github.com/alexdobin/STAR) (Spliced aware ultrafast transcript alligner to reference genome)

 * [StringTie 2.2.1](https://ccb.jhu.edu/software/stringtie/) (A fast and highly efficient assembler of RNA-Seq alignments into potential transcripts.)

## About-Bulk-RNA-Snakeline
The Bioinformatics Core team at Allen Institute, currently has a pipeline in place to process raw Bulk RNA-Seq data. However, the existing pipeline requires users to execute a series of custom bash scripts for every step in the workflow. Not only is this time-consuming, but requires additional effort from the user to ensure each script is executed properly with the right parameter adjustments according to the data and its file path. With this method, it is important to understand that any user error may affect downstream analysis and ultimately risk the accuracy of the results. Additionally, users can be challenged with input and output compatibility issues when running multiple scripts. This is when the output files generated from script A fail to be compatible with the inputs into script B because of file formatting and/or versioning. There also needs to be a check on the virtual environment, ensuring every software tool is installed successfully with all the necessary dependencies. In order to minimize the number of manual steps that are required to execute the processing workflow on Bulk RNA-Seq data, the BiCore team is migrating from a basic pipeline written in Unix shell to Snakemake. Snakemake is an easy to use workflow engine that can be used to process data through well defined rules. Each rule contains a set of input and output files, parameters; the computational tasks that will be executed, and optionally a path to the environment. This is a unique feature offered by Snakemake that increases readability by reducing the complexity of the code. Snakemake was designed specifically for Bioinformatics analysis and is the reason it is known as a domain-specific language (DSL). Snakemake was determined as the most suitable workflow engine for the BiCore team because it includes the beneficial properties of portability, readability, reproducibility, scalability, and reusability.  

## Pipeline Overview
![alt text](Image/pipeline.png)

## Directory Structure
![alt text](Image/dir_structure.png)
  
## Authors and History

* Beagan Nguy - Algorithm Design
* Anish Chakka - Project Manager

## Acknowledgments

Allen Institute Bioinformatics Core Team
 
## References
Johannes Köster, Sven Rahmann, Snakemake—a scalable bioinformatics workflow engine, Bioinformatics, Volume 28, Issue 19, 1 October 2012, Pages 2520–2522, https://doi.org/10.1093/bioinformatics/bts480
