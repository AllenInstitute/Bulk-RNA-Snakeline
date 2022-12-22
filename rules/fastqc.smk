rule fastqc:
    input:
        reads_raw="/Pipeline/Fastq/Raw/{sample}_{read_no}_001.fastq.gz",
        reads_cutadapt="/Pipeline/Fastq/CutAdapt/{sample}_{read_no}_001.cutadapt.fastq.gz"
    output:
        multiext("/Pipeline/QC/Raw/{sample}_{read_no}_001_fastqc", ".html", ".zip"),
        multiext("/Pipeline/QC/CutAdapt/{sample}_{read_no}_001.cutadapt_fastqc", ".html", ".zip")
    params:
        raw_dir="/Pipeline/QC/Raw",
        cutadapt_dir="/Pipeline/QC/CutAdapt"
    priority:
        4
    shell:
        """
        fastqc -o {params.raw_dir} {input.reads_raw} 
        fastqc -o {params.cutadapt_dir} {input.reads_cutadapt} 
        """
