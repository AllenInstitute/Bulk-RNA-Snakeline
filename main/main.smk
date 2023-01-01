configfile: '/configs/config.yml'

rule all:
    input:
        expand("/Pipeline/QC/Raw/{sample}_{read_no}_001_fastqc.{ext}", sample=SAMPLES, read_no=['R1', 'R2'], ext=['html', 'zip']),
        expand("/Pipeline/QC/CutAdapt/{sample}_{read_no}_001.cutadapt_fastqc.{ext}", sample=SAMPLES, read_no=['R1', 'R2'], ext=['html', 'zip']),
        expand("/Pipeline/StringTie/{sample}/{sample}Aligned.sortedByCoord.out.bam", sample=SAMPLES)
        "/Pipeline/STAR/out",
        expand("/Pipeline/Fastq/CutAdapt/{sample}_{read_no}_001.cutadapt.fastq.gz", sample=SAMPLES, read_no=['R1', 'R2']),
        


include: "rules/cutadapt.smk"
include: "rules/qc.smk"

if config['star_supplied']['genome_dir'] != "False":
    include: "rules/rule1.smk"
    include: "rules/star.smk"
else:
    include: "rules/genome.smk"
    include: "rules/nstar.smk"

include: "rules/stringTie.smk"
    
    
