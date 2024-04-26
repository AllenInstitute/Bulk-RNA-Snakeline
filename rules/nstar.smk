# Rule for running STAR on trimmed RNA-seq data to align reads to the reference genome
rule star:
    # Input files: trimmed FASTQ files from the Cutadapt rule
    input:
        read_1="Pipeline/Fastq/CutAdapt/{sample}_R1_001.cutadapt.fastq.gz",
        read_2="Pipeline/Fastq/CutAdapt/{sample}_R2_001.cutadapt.fastq.gz"
    # Output files: aligned BAM file, transcriptome-aligned BAM file, and gene counts
    output:
        bam = "Pipeline/STAR/out/{sample}/{sample}Log.final.out",
        log_final = "Pipeline/STAR/out/{sample}/{sample}Aligned.sortedByCoord.out.bam"
    params:
        genome_dir=config['star_nsupplied']['genome_dir'],
        proj_dir="Pipeline/STAR/out/{sample}"
    threads: 
        config['star_nsupplied']['threads'] 
    resources:
        mem_mb=60000
    log:
        "logs/STAR/{sample}.log"
    priority:
        3
    shell:
        "mkdir -p Pipeline/STAR/out/{wildcards.sample} && "
        "STAR "
        "--readFilesIn {input.read_1} {input.read_2} "
        "--readFilesCommand zcat "
        "--outSAMattrRGline ID:{wildcards.sample} "
        "--outSAMstrandField intronMotif "
        "--genomeDir {params.genome_dir} "
        "--genomeLoad NoSharedMemory "
        "--outFileNamePrefix {params.proj_dir}/{wildcards.sample} "
        "--outSAMtype BAM SortedByCoordinate "
        "--quantMode TranscriptomeSAM GeneCounts "
        "--runThreadN {threads} "
        "--twopassMode Basic > {log} 2>&1"
