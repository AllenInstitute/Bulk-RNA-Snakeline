rule stringTie:
    input:
        gtf=config['stringTie']['gtf']
    output:
        bam="Pipeline/StringTie/out/{sample}/{sample}Aligned.sortedByCoord.out.bam"
    params:
        transcript="Pipeline/StringTie/{sample}/{sample}.transcripts.gtf",
        gene_abund="Pipeline/StringTie/{sample}/{sample}.gene_abund.tab"
    threads:
        12
    priority:
        1
    shell:
        "stringtie -G {input.gtf} "
        "-e "
        "-o {params.transcript} "
        "-A {params.gene_abund} "
        "--fr "
        "-p {threads} "
        "Pipeline/STAR/{wildcards.sample}/{wildcards.sample}Aligned.sortedByCoord.out.bam"
