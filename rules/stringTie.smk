# Rule for running StringTie on aligned RNA-seq data to assemble and quantify transcripts
rule stringTie:
    # Input files: reference GTF file and aligned BAM file from the STAR rule
    input:
        gtf=config['stringTie']['gtf_path'],
        bam="Pipeline/STAR/out/{sample}/{sample}Aligned.sortedByCoord.out.bam"
    # Output files: assembled transcripts in GTF format and gene abundance estimates in a tabular format
    output:
        transcripts="Pipeline/StringTie/{sample}/{sample}.transcripts.gtf",
        gene_abund="Pipeline/StringTie/{sample}/{sample}.gene_abund.tab"
    threads:
        config['stringTie']['threads']
    log:
        "logs/stringTie/{sample}.log"
    priority:
        1
    shell:
        "stringtie -G {input.gtf} "
        "-e "
        "-o {output.transcripts} "
        "-A {output.gene_abund} "
        "--fr "
        "-p {threads} "
        "{input.bam} > {log} 2>&1"

