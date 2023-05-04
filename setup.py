'''
Summary
1) get_args(): Parses command-line arguments.
2) create_directories(): Creates the necessary directories for the pipeline.
3) search_fastq_files(): Searches for FastQ files in the current directory.
4) move_fastq_files(): Moves FastQ files to the 'Raw' directory.
5) get_fastq_name_list(): Retrieves a list of FastQ file names based on the provided sample list or from the 'Raw' directory.
6) update_config_yml(): Updates the 'config.yml' file with the sorted FastQ names.
7) check_star_version(): Checks whether the installed STAR version matches the STAR index version.
8) main(): Main function that executes the script by calling the above functions in the appropriate order.
'''
import os
import re
import sys
import argparse


def get_args():
    parser = argparse.ArgumentParser(
        description='Optional arguments: -s', usage='python3 setup.py -s <sample_list.txt>'
    )

    parser.add_argument(
        '-s', '-sample', help='Input list of sample names', required=False
    )

    return parser.parse_args()


def create_directories():
    # Make Directories for FASTQ files
    os.makedirs('Pipeline/Fastq/Raw', exist_ok=True)
    os.makedirs('Pipeline/Fastq/CutAdapt', exist_ok=True)

    # Make Directories for QC files
    os.makedirs('Pipeline/QC/Raw', exist_ok=True)
    os.makedirs('Pipeline/QC/CutAdapt', exist_ok=True)

    # Make Directories for STAR
    os.makedirs('Pipeline/STAR/out', exist_ok=True)
    os.makedirs('Pipeline/STAR/genome/out', exist_ok=True)

    # Make Directories for StringTie
    os.makedirs('Pipeline/StringTie', exist_ok=True)


def search_fastq_files(current_dir, get_fastq):
    r1_list = []
    r2_list = []

    for root, _, files in os.walk(current_dir):
        for file in files:
            res = re.match(get_fastq, file)
            if res:
                if res.group(1):
                    r1_list.append(os.path.join(root, file))
                if res.group(2):
                    r2_list.append(os.path.join(root, file))

    return r1_list, r2_list


def move_fastq_files(r1_list, r2_list):
    for fastq_file_path in r1_list:
        if 'Pipeline/Fastq/Raw' not in fastq_file_path:
            os.system('mv {} Pipeline/Fastq/Raw'.format(fastq_file_path))

    for fastq_file_path in r2_list:
        if 'Pipeline/Fastq/Raw' not in fastq_file_path:
            os.system('mv {} Pipeline/Fastq/Raw'.format(fastq_file_path))


def get_fastq_name_list(args):
    fastq_name_list = []

    if args.s:
        with open(args.s, 'r') as sample_txt_open:
            for sample_name in sample_txt_open:
                if sample_name != "":
                    fastq_name_list.append(sample_name.rstrip())
    else:
        fastq_files_list = os.listdir('Pipeline/Fastq/Raw')
        for fastq_files in sorted(fastq_files_list):
            if 'R1' in fastq_files:
                suffix_fastq_file = fastq_files.replace("_R1_001.fastq.gz", "")
                fastq_name_list.append(suffix_fastq_file)
            else:
                suffix_fastq_file = fastq_files.replace("_R2_001.fastq.gz", "")
                fastq_name_list.append(suffix_fastq_file)

    return fastq_name_list

def update_config_yml(fastq_name_list):
    sorted_fastq = sorted([*set(fastq_name_list)])

    with open('configs/config.yml', 'r') as f:
        lines = f.readlines()
        io_index = len(lines)

        if '# Append\n' in lines:
            io_index = lines.index('# Append\n')

    with open('configs/config.yml', 'w') as f:
        filtered_lines = lines[0: io_index+1]
        f.writelines(filtered_lines)

    with open('configs/config.yml', 'a') as f:
        f.write(' {}'.format(sorted_fastq))

def calculate_total_threads(num_samples):
    with open('configs/config.yml', 'r') as f:
        config_data = f.read()

    cutadapt_threads = int(re.search(r'cutadapt:\n\s*threads:\s*(\d+)', config_data).group(1))
    fastqc_threads = int(re.search(r'fastqc:\n\s*threads:\s*(\d+)', config_data).group(1))
    star_index_threads = int(re.search(r'star_index:\n\s*threads:\s*(\d+)', config_data).group(1))
    star_nsupplied_threads = int(re.search(r'star_nsupplied:\n\s*threads:\s*(\d+)', config_data).group(1))
    star_supplied_threads = int(re.search(r'star_supplied:\n\s*threads:\s*(\d+)', config_data).group(1))
    stringTie_threads = int(re.search(r'stringTie:\n\s*threads:\s*(\d+)', config_data).group(1))

    total_threads_per_sample = cutadapt_threads + fastqc_threads + star_index_threads + star_nsupplied_threads + star_supplied_threads + stringTie_threads

    total_threads = total_threads_per_sample * num_samples

    return total_threads

def check_star_version(total_threads):
    with open('configs/config.yml', 'r', encoding='utf-8') as file:
        config_data = file.readlines()

        star_index_path = config_data[30]
        split_star_index_path = star_index_path.split('"')
        split_star_version_index_line = []

        if star_index_path != "False":
            try:
                with open('{}/genomeParameters.txt'.format(split_star_index_path[1]), 'r', encoding='utf-8') as file:
                    genome_param = file.readlines()
                    star_version_index_line = genome_param[2].rstrip()
                    split_star_version_index_line = star_version_index_line.split('\t')
            except:
                raise Exception("\n\n Double Check: '{}' EXIST".format(split_star_index_path))

        starversion = config_data[16].split('"')
        if starversion[1].split('v')[1] != split_star_version_index_line[1]:
            raise Exception("\n\n STAR Version installed: {} is not the same STAR version used to build STAR index directory: {}".format(starversion[1].split('v')[1], split_star_version_index_line[1]))
        else:
            print('Setup is Complete...continue to run snakemake pipeline with the following command:\n')
            print('srun --partition=celltypes --mem=200g --time=24:00:00 snakemake --cores {} -s main.smk\n'.format(total_threads))
            print('Or\n')
            print('sbatch run.sh')

def main():
    args = get_args()

    create_directories()

    get_fastq = re.compile('(.*R1_\d*.fastq.gz$)|(.*R2_\d*.fastq.gz$)')

    current_dir = os.getcwd()
    r1_list, r2_list = search_fastq_files(current_dir, get_fastq)

    move_fastq_files(r1_list, r2_list)

    fastq_name_list = get_fastq_name_list(args)

    update_config_yml(fastq_name_list)

    total_threads = calculate_total_threads(len(fastq_name_list))

    check_star_version(total_threads)


if __name__ == '__main__':
    main()
