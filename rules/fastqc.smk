configfile: '../config/config.yml'
  
rule fastqc_rule:
    input:
      read1=config[io_name][sample1],
      read2=config[io_name][sample2]
    output:
      foward=config[io_name][sample1],
      reverse='config[io_name][sample1]
    shell
    """
    fastqc -o {output.forward} {input.read1}
    fastqc -o {output.reverse} {input.read2}
    """
