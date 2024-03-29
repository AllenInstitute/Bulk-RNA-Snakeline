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
    snakemake --cores 160 -s <snakefile>
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
The Allen Institute's Bioinformatics Core team currently employs a pipeline to process raw Bulk RNA-Seq data. This existing pipeline, however, relies on users executing a series of custom bash scripts for each workflow step. This approach is not only time-consuming but also demands extra effort from users to ensure proper script execution, correct parameter adjustments, and accurate file paths. It is crucial to recognize that user errors can negatively impact downstream analyses and compromise result accuracy.

Furthermore, users often face input and output compatibility issues when running multiple scripts. Incompatibilities arise when the output files generated by one script are not compatible with the inputs required for another script due to differences in file formats or software versions. Additionally, the virtual environment must be checked to guarantee the successful installation of all necessary software tools and dependencies.

To minimize manual intervention and enhance the efficiency of processing Bulk RNA-Seq data, the BiCore team is transitioning from a basic Unix shell pipeline to Snakemake. As a user-friendly workflow engine, Snakemake processes data through well-defined rules, each consisting of input and output files, parameters, computational tasks, and, optionally, an environment path. Snakemake's unique features reduce code complexity and enhance readability. Designed specifically for bioinformatics analyses, Snakemake is a domain-specific language (DSL) that offers portability, readability, reproducibility, scalability, and reusability, making it the ideal choice for the BiCore team's needs.

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
