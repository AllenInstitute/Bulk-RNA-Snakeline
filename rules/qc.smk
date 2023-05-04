rule fastqc_raw:
    input:
        reads_raw="Pipeline/Fastq/Raw/{sample}_{read_no}_001.fastq.gz"
    output:
        multiext("Pipeline/QC/Raw/{sample}_{read_no}_001_fastqc", ".html", ".zip")
    params:
        raw_dir="Pipeline/QC/Raw"
    threads:
        config['fastqc']['threads']
    log:
        "logs/fastqc_raw/{sample}_{read_no}.log"
    priority:
        6
    shell:
        "mkdir -p logs/fastqc_raw && "
        "fastqc -o {params.raw_dir} -t {threads} {input.reads_raw} > {log} 2>&1"


rule fastqc_trimmed:
    input:
        reads_cutadapt="Pipeline/Fastq/CutAdapt/{sample}_{read_no}_001.cutadapt.fastq.gz"
    output:
        multiext("Pipeline/QC/CutAdapt/{sample}_{read_no}_001.cutadapt_fastqc", ".html", ".zip")
    params:
        cutadapt_dir="Pipeline/QC/CutAdapt"
    threads:
        config['fastqc']['threads']
    log:
        "logs/fastqc_trimmed/{sample}_{read_no}.log"
    priority:
        4
    shell:
        "mkdir -p logs/fastqc_trimmed && "
        "fastqc -o {params.cutadapt_dir} -t {threads} {input.reads_cutadapt} > {log} 2>&1"

