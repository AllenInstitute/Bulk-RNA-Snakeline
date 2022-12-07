configfile: '../configs/config.yml'
rule cutadapt:
  input:
    read1="config['io_name']['sample_1']",
    read2="config['io_name']['sample_2']"
  output:
    forwardPaired="config['cutadapt']['fadapter']",
    reversePaired="config['cutadapt']['radapter']"
  threads:
    4
  params:
    fadapter="AGATCGGAAGAGCACACGTCTGAACTCCAGTCA",
    radapter="AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT",
  shell:
    """
    mkdir -p out
    cutadapt -u 3 
      -a {params.fadapter} 
      -A {params.radapter} 
      -o ../FASTQ/CutAdapt/{output.forwardPaired} 
      -p ../FASTQ/CutAdapt/{output.reversePaired}
      -m 25 
      -q 15
      -j {threads} 
      {input_read1} 
      {input_read2}
    """
