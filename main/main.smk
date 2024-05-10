configfile: 'configs/config.yml'
SAMPLES = config['sample']

# Condition where star index is supplied
if config['star_supplied']['genome_dir'] != "False":
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
            # Output from multiqc
            "Pipeline/QC/MultiQC/multiqc_report.html"
    include: "rules/trim.smk"
    include: "rules/qc.smk"
    include: "rules/star.smk"
    include: "rules/stringTie.smk"
    include: "rules/multiqc.smk"
else:
    rule all:
        input:
            expand("Pipeline/Fastq/CutAdapt/{sample}_{read_no}_001.cutadapt.fastq.gz", sample=SAMPLES, read_no=['R1', 'R2']),
            # Output quality control summary of raw fastq
            expand("Pipeline/QC/Raw/{sample}_{read_no}_001_fastqc.{ext}", sample=SAMPLES, read_no=['R1', 'R2'], ext=['html', 'zip']),
            # Output quality control summary of trimmed fastq
            expand("Pipeline/QC/CutAdapt/{sample}_{read_no}_001.cutadapt_fastqc.{ext}", sample=SAMPLES, read_no=['R1', 'R2'], ext=['html', 'zip']),
            # Output STAR Index
            "Pipeline/STAR/genome/{}/SAindex".format(config['star_version']),
            # Output aligned bam files from STAR
            expand("Pipeline/STAR/out/{sample}/{sample}Aligned.sortedByCoord.out.bam", sample=SAMPLES),
            expand("Pipeline/STAR/out/{sample}/{sample}Log.final.out", sample=SAMPLES),
            # Output from stringtie
            expand("Pipeline/StringTie/{sample}/{sample}.transcripts.gtf", sample=SAMPLES),
            expand("Pipeline/StringTie/{sample}/{sample}.gene_abund.tab", sample=SAMPLES)
            # Output from multiqc
            "Pipeline/QC/MultiQC/multiqc_report.html"
    include: "rules/trim.smk"
    include: "rules/qc.smk"
    include: "rules/genome.smk"
    include: "rules/nstar.smk"
    include: "rules/stringTie.smk"
    include: "rules/multiqc.smk"

