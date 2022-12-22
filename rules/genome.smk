rule starIndex:
    input: 
        assembly=config['star_index']['assembly_path'],
        gtf=config['star_index']['gtf_path']
    output:
        genome_dir="/Pipeline/STAR/genome/config['star_version']",
    params:
        numOverhang=config['star_index']['overhang']
    threads:
        config['threads']
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
