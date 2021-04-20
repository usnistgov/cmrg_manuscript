import argparse
import subprocess

parser = argparse.ArgumentParser(description="Subset bed file to callable regions only")
parser.add_argument('--input_benchmark', metavar="I", type=str, nargs="+", help="input bed file")
parser.add_argument('--input_file_list', metavar="F", type=str, nargs="+", help="input file_list")
parser.add_argument('--output', metavar=")", type=str, nargs="+", help="output file")
args = parser.parse_args()

f_exon_file = open(args.input_file_list[0], "r")
exon_file_lines = f_exon_file.readlines()
f_out = open(args.output[0], "w+")

for exon_file in exon_file_lines:
    print(exon_file)
    gene_name = exon_file.split("exons_file_")[1].strip(".bed")
    intersect_size = subprocess.check_output("cat " + exon_file.strip() + " | sed 's/^chr//' | sort -k1,1 -k2,2n | sed 's/^/chr/' | bedtools merge -i stdin | bedtools intersect -a " + args.input_benchmark[0] + " -b  stdin  | wc -l", shell = True)
    try:
        f_out.write(str(intersect_size.strip()) + "\t" + gene_name.strip() + "\n")
        f_out.flush()
    except:
        f_out.write("0\t" + gene_name.strip() + "\n")
        f_out.flush()
    

f_out.close()
