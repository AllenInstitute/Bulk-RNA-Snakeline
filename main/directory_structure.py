import os
import re

# Make Directories for FASTQ files
os.system('mkdir -p pipeline')
os.system('mkdir -p pipeline/FASTQ')
os.system('mkdir -p pipeline/FASTQ/RAW')
os.system('mkdir -p pipeline/FASTQ/CutAdapt')

# Make Directories for QC files
os.system('mkdir -p pipeline/QC')
os.system('mkdir -p pipeline/QC/RAW')
os.system('mkdir -p pipeline/QC/Cutadapt')

# Make Directories for STAR
os.system('mkdir -p pipeline/STAR')

# Make Directories for StringTie
os.system('mkdir -p pipeline/StringTie')

get_fastq = re.compile('(.*R1.*fastq.gz$)|(.*R2.*fastq.gz$)')

# Search for fastq files
r1_list = list()
r2_list = list()
current_dir = os.getcwd()
for root, dirs, files in os.walk(current_dir):
    for file in files:
        res = re.match(get_fastq, file)
        if res:
            if res.group(1):
                r1_list.append(os.path.join(root, file))
            if res.group(2):
                r2_list.append(os.path.join(root, file))

# Move Fastq files to raw directory
for fastq_file_path in r1_list:
    if 'pipeline/FASTQ/RAW' not in fastq_file_path:
        os.system('mv {} pipeline/FASTQ/RAW'.format(fastq_file_path))


for fastq_file_path in r2_list:
    if 'pipeline/FASTQ/RAW' not in fastq_file_path:
        os.system('mv {} pipeline/FASTQ/RAW'.format(fastq_file_path))

# Output fastq files to sample_list.txt
fout = open('sample_list.txt', 'w')

fastq_files_list = os.listdir('pipeline/FASTQ/RAW')
for fastq_files in sorted(fastq_files_list):
    fout.write('{}\n'.format(fastq_files))

fout.close()

# Clear existing input and output names for the samples
fappen = open('../configs/config.yml', 'r')
lines = fappen.readlines()
io_index = len(lines)
if 'io_name: \n' in lines:
    io_index = lines.index('io_name: \n')
fappen.close()

fappen = open('../configs/config.yml', 'w')
filtered_lines = lines[0: io_index]
for line in filtered_lines:
    fappen.write(line)
fappen.close()

# Append config yml file by adding input and output names for the samples
fappen = open('../configs/config.yml', 'a')
fappen.write("io_name: {}".format('\n'))

for count, fastq_files in enumerate(sorted(fastq_files_list)):
    fappen.write('{}sample_{}: {}\n'.format('\t', count, fastq_files))

fappen.close()

