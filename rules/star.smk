rule star:
    input:
        read_1="/Pipeline/Fastq/CutAdapt/{sample}_R1_001.cutadapt.fastq.gz",
        read_2="/Pipeline/Fastq/CutAdapt/{sample}_R2_001.cutadapt.fastq.gz"
    output:
        out_dir="/Pipeline/STAR/out"
    params:
        genome_dir=config['star_supplied']
    threads:
        12  # Set the maximum number of available cores
    resources:
        mem_mb=60000
    priority:
        2
    shell:
        "STAR "
        "--readFilesIn {input.read_1} {input.read_2} "
        "--readFilesCommand zcat "
        "--outSAMattrRGline ID:{sample} "
        "--outSAMstrandField intronMotif "
        "--genomeDir {params.genome_dir} "
        "--genomeLoad NoSharedMemory "
        "--outFileNamePrefix {output.out_dir}/{sample} "
        "--outSAMtype BAM SortedByCoordinate "
        "--quantMode TranscriptomeSAM GeneCounts "
        "--runThreadN {threads} "
        "--twopassMode Basic"
