rule multiqc:
    input:
        fastqc_raw="Pipeline/QC/Raw",
        fastqc_trimmed="Pipeline/QC/CutAdapt",
        star_logs="Pipeline/STAR/out"
        string_tie="Pipeline/StringTie"
    output:
        output_html="Pipeline/QC/MultiQC/multiqc_report.html"
    threads:
        config['multiqc']['threads']
    resources:
        mem_mb=10000
    log:
        "logs/multiqc/multiqc.log"
    priority:
        1
    shell:
        "mkdir -p Pipeline/QC/MultiQC && " 
        "multiqc Pipeline/QC/Raw Pipeline/QC/CutAdapt Pipeline/STAR/out Pipeline/StringTie -o Pipeline/QC/MultiQC"
