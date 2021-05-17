### Next Steps
## Add strat coverage
## Add var table count methods
## Look into adding other stats from main table


from snakemake.utils import min_version

### set minimum snakemake version
min_version("5.27.4")

## Loading config file and sample sheet
# configfile: "config/config.yaml"

## Variables for data paths
mrg_dir = "resources/NIST_MedicalGene_v1.00.01"
benchdir = "workflow/data/benchmark_sets"
ensembl_dir = "workflow/data/gene_coords"

## Defining Wildcards
REFS = ["GRCh37","GRCh38"]
REGIONS = ["gene","exon","intron"]
BENCHTYPES = ["smallvar","SV", "union"]
BENCHSETS = ["v4", "mrg"]

wildcard_constraints:
    ref="|".join(REFS),
    region="|".join(REGIONS),
    benchset="|".join(BENCHSETS),
    benchtype="|".join(BENCHTYPES)

## Define target files for pipeline
rule all:
    input:
        expand(benchdir + "/{ref}/HG002_{ref}_mrg_union.bed", 
                ref = REFS),
        expand("data/gene_stat_tbls/cov_tbls/HG002_{ref}_mrg_{benchtype}_{region}_cov.tsv", 
                ref = REFS, region = REGIONS, benchtype = BENCHTYPES),
        expand("data/gene_stat_tbls/cov_tbls/HG002_{ref}_v4_smallvar_{region}_cov.tsv", 
                ref = REFS, region = REGIONS)#,
        # expand("data/gene_stat_tbls/cov_inputs/allDiff_{ref}_mrg_{region}_cov.tsv", 
        #         ref = REFS, region = REGIONS)

################################################################################
## Preparing input files
################################################################################

rule make_mrg_sym_links:
    input:
        mrg_37_smallvar_vcf=mrg_dir + "/HG002_GRCh37_difficult_medical_gene_smallvar_benchmark_v1.00.01.vcf.gz",
        mrg_37_smallvar_bed=mrg_dir + "/HG002_GRCh37_difficult_medical_gene_smallvar_benchmark_v1.00.01.bed",
        mrg_37_sv_vcf=mrg_dir + "/HG002_GRCh37_difficult_medical_gene_SV_benchmark_v1.00.01.vcf.gz",
        mrg_37_sv_bed=mrg_dir + "/HG002_GRCh37_difficult_medical_gene_SV_benchmark_v1.00.01.bed",
        mrg_38_smallvar_vcf=mrg_dir + "/HG002_GRCh38_difficult_medical_gene_smallvar_benchmark_v1.00.01.vcf.gz",
        mrg_38_smallvar_bed=mrg_dir + "/HG002_GRCh38_difficult_medical_gene_smallvar_benchmark_v1.00.01.bed",
        mrg_38_sv_vcf=mrg_dir + "/HG002_GRCh38_difficult_medical_gene_SV_benchmark_v1.00.01.vcf.gz",
        mrg_38_sv_bed=mrg_dir + "/HG002_GRCh38_difficult_medical_gene_SV_benchmark_v1.00.01.bed"
    output:     
        mrg_37_smallvar_vcf=benchdir + "/HG002_GRCh37_mrg_smallvar.vcf.gz",
        mrg_37_smallvar_bed=benchdir + "/HG002_GRCh37_mrg_smallvar.bed",
        mrg_37_sv_vcf=benchdir + "/HG002_GRCh37_mrg_SV.vcf.gz",
        mrg_37_sv_bed=benchdir + "/HG002_GRCh37_mrg_SV.bed",
        mrg_38_smallvar_vcf=benchdir + "/HG002_GRCh38_mrg_smallvar.vcf.gz",
        mrg_38_smallvar_bed=benchdir + "/HG002_GRCh38_mrg_smallvar.bed",
        mrg_38_sv_vcf=benchdir + "/HG002_GRCh38_mrg_SV.vcf.gz",
        mrg_38_sv_bed=benchdir + "/HG002_GRCh38_mrg_SV.bed"
    shell: """
        cp {input.mrg_37_smallvar_vcf} {output.mrg_37_smallvar_vcf}
        cp {input.mrg_37_smallvar_bed} {output.mrg_37_smallvar_bed}
        cp {input.mrg_37_sv_vcf} {output.mrg_37_sv_vcf}
        cp {input.mrg_37_sv_bed} {output.mrg_37_sv_bed}
        cp {input.mrg_38_smallvar_vcf} {output.mrg_38_smallvar_vcf}
        cp {input.mrg_38_smallvar_bed} {output.mrg_38_smallvar_bed}
        cp {input.mrg_38_sv_vcf} {output.mrg_38_sv_vcf}
        cp {input.mrg_38_sv_bed} {output.mrg_38_sv_bed}
    """

rule make_v4_symlinks:
    input:
        v4_37_smallvar_vcf = "resources/HG002_GRCh37_1_22_v4.2.1_benchmark.vcf.gz",
        v4_37_smallvar_bed = "resources/HG002_GRCh37_1_22_v4.2.1_benchmark_noinconsistent.bed",
        v4_38_smallvar_vcf = "resources/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz",
        v4_38_smallvar_bed = "resources/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"
    output:
        v4_37_smallvar_vcf = benchdir + "/HG002_GRCh37_v4_smallvar.vcf.gz",
        v4_37_smallvar_bed = benchdir + "/HG002_GRCh37_v4_smallvar.bed",
        v4_38_smallvar_vcf = benchdir + "/HG002_GRCh38_v4_smallvar.vcf.gz",
        v4_38_smallvar_bed = benchdir + "/HG002_GRCh38_v4_smallvar.bed"
    shell: """
        cp {input.v4_37_smallvar_vcf} {output.v4_37_smallvar_vcf}
        cp {input.v4_37_smallvar_bed} {output.v4_37_smallvar_bed}
        cp {input.v4_38_smallvar_vcf} {output.v4_38_smallvar_vcf}
        cp {input.v4_38_smallvar_bed} {output.v4_38_smallvar_bed}
    """

################################################################################
## Combined SM and SV bed file
################################################################################

rule make_union_bed: 
    input:
        sm = benchdir + "/HG002_{ref}_mrg_smallvar.bed",
        sv = benchdir + "/HG002_{ref}_mrg_SV.bed"
    output: benchdir + "/HG002_{ref}_mrg_union.bed"
    conda: "envs/bedtools.yml"
    shell: """
        multiintersectbed \
            -i {input.sm} {input.sv} \
            | sortBed -i stdin \
            | mergeBed \
            -i stdin > {output}
    """

################################################################################
## Intron Region Bed 
################################################################################

rule make_intron_bed: 
    input: 
        exon = ensembl_dir + "/{ref}_mrg_full_exon.bed",
        gene = ensembl_dir + "/{ref}_mrg_full_gene.bed"
    output: ensembl_dir + "/{ref}_mrg_full_intron.bed"
    conda: "envs/bedtools.yml"
    shell: """
        subtractBed \
            -a {input.gene} -b {input.exon} \
            > {output}
    """


################################################################################
## Calculate Included Bases
################################################################################

## Using symbolic links for consistent benchmark region files
rule calc_gene_coverage:
    input:
        a=ensembl_dir + "/{ref}_mrg_full_{region}.bed",
        b=benchdir + "/HG002_{ref}_{benchmarkset}_{benchtype}.bed"
    output: "data/gene_stat_tbls/cov_tbls/HG002_{ref}_{benchmarkset}_{benchtype}_{region}_cov.tsv"
    threads: 2
    wrapper: "0.74.0/bio/bedtools/coveragebed"


# rule calc_strat_coverage:
#     input:
#         a=TODO - replace with all difficult strat,
#         b="data/mrg_lists/ENSEMBL_coordinates/{ref}_Medical_Gene_{region}.bed"
#     output: "data/gene_stat_tbls/cov_inputs/allDiff_{ref}_mrg_{region}_cov.tsv"
#     threads: 2
#     wrapper: "0.74.0/bio/bedtools/coveragebed"
