rule starIndex:
    input: 
        assembly=config['star_index']['assembly_path'], # Provide your reference FASTA file
        gtf=config['star_index']['gtf_path']    # Provide your GTF file
    output:
        genome_dir="/Pipeline/STAR/genome/config['star_version']",
        # Alt directory('/Pipeline/STAR/genome/config['star_version']')
    params:
        numOverhang=config['star_index']['overhang']    # Num Overhang Nucleotides
    threads:
        config['threads']   # Set the maximum number of available cores
    resources:
        mem_mb=60000
    priority:
        3
    shell:
        "STAR "
        "--runMode genomeGenerate "
        "--genomeDir {output.genome_dir} "
        "--genomeFastaFiles {input.assembly} "
        "--genomeChrBinNbits 10"
        "--sjdbGTFfile {input.gtf} "
        "--sjdbOverhang {params.numOverhang}"
        "--runThreadN {threads}"
