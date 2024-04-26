rule cutadapt:
    input:
        read_1="Pipeline/Fastq/Raw/{sample}_R1_001.fastq.gz",
        read_2="Pipeline/Fastq/Raw/{sample}_R2_001.fastq.gz"
    output:
        read_1="Pipeline/Fastq/CutAdapt/{sample}_R1_001.cutadapt.fastq.gz",
        read_2="Pipeline/Fastq/CutAdapt/{sample}_R2_001.cutadapt.fastq.gz"
    params:
        fadapter=config['cutadapt']['fadapter'],
        radapter=config['cutadapt']['radapter'],
        cut=config['cutadapt']['cut'],
        min=config['cutadapt']['min'],
        quality_score=config['cutadapt']['quality_score'],  
    threads:
        config['cutadapt']['threads']
    log:
        "logs/CutAdapt/{sample}_cutadapt.log"
    priority:
        6
    shell:
        "cutadapt -u {params.cut} " # First 3 base r1
	    "-a {params.fadapter} " 
        "-A {params.radapter} "
        "-o {output.read_1} "
        "-p {output.read_2} "
        "-m {params.min} " # Min len
        "-q {params.quality_score} " # Quality Score per base
        "-j {threads} " # Cores
        "{input.read_1} "
        "{input.read_2} > {log} 2>&1"
