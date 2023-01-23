rule star:
    input:
        read_1="Pipeline/Fastq/CutAdapt/{sample}_R1_001.cutadapt.fastq.gz",
        read_2="Pipeline/Fastq/CutAdapt/{sample}_R2_001.cutadapt.fastq.gz"
    output:
        align_bam="Pipeline/STAR/out/{sample}/{sample}Aligned.toTranscriptome.out.bam"
    params:
        genome_dir=config['star_nsupplied']['genome_dir'],
        out_dir="Pipeline/STAR/out"
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
        "--outSAMattrRGline ID:{wildcards.sample} "
        "--outSAMstrandField intronMotif "
        "--genomeDir {params.genome_dir} "
        "--genomeLoad NoSharedMemory "
        "--outFileNamePrefix {params.out_dir}/{wildcards.sample} "
        "--outSAMtype BAM SortedByCoordinate "
        "--quantMode TranscriptomeSAM GeneCounts "
        "--runThreadN {threads} "
        "--twopassMode Basic"
