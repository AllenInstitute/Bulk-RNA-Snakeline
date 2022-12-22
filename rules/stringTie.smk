rule stringTie:
    input:
        bam_dir="/Pipeline/STAR"
        gtf=config['stringTie']['gtf_path']
    output:
        bam="/Pipeline/StringTie/{sample}/{sample}Aligned.sortedByCoord.out.bam"
    params:
        transcript="/Pipeline/StringTie/{sample}.transcripts.gtf",
        gene_abund="/Pipeline/StringTie/{sample}.gene_abund.tab"
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
        "{bam_dir}/{sample}/{sample}Aligned.sortedByCoord.out.bam"
