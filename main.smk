configfile: 'configs/config.yml'
SAMPLES = config['sample']

rule all:
    input:
        expand("Pipeline/Fastq/CutAdapt/{sample}_{read_no}_001.cutadapt.fastq.gz", sample=SAMPLES, read_no=['R1', 'R2']),
        # Output quality control summary of raw fastq
        expand("Pipeline/QC/Raw/{sample}_{read_no}_001_fastqc.{ext}", sample=SAMPLES, read_no=['R1', 'R2'], ext=['html', 'zip']),
        # Output quality control summary of trimmed fastq
        expand("Pipeline/QC/CutAdapt/{sample}_{read_no}_001.cutadapt_fastqc.{ext}", sample=SAMPLES, read_no=['R1', 'R2'], ext=['html', 'zip']),
        # Output aligned bam files from STAR
        expand("Pipeline/STAR/out/{sample}/{sample}Aligned.sortedByCoord.out.bam", sample=SAMPLES),
        expand("Pipeline/STAR/out/{sample}/{sample}Log.final.out", sample=SAMPLES),
        # Output from stringtie
        expand("Pipeline/StringTie/{sample}/{sample}.transcripts.gtf", sample=SAMPLES),
        expand("Pipeline/StringTie/{sample}/{sample}.gene_abund.tab", sample=SAMPLES)

# Case where star index directory is supplied
if config['star_supplied']['genome_dir'] != "False":
    #include: "rules/rule1.smk"  # rule all 1
    include: "rules/trim.smk"
    include: "rules/qc.smk"
    include: "rules/star.smk"
else:
    print('genome')
    #include: "rules/rule2.smk"  # rule all 2
    include: "rules/trim.smk"
    include: "rules/qc.smk"
    include: "rules/genome.smk"
    include: "rules/nstar.smk"

include: "rules/stringTie.smk"
    
