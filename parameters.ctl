#input and output paths
BOOTSTRAP_DIR = path_to_directory_with_bootstrapped_gene_trees
BOOTSTRAP_SUFFIX = boottrees
SNAQ_OUTPUT = path_to_output_directory_from_snaq

#scheduler for cluster
#if running locally, just change to bash and modify template file appropriately
SCHEDULER = sbatch

#full-length path to desired version of Julia binary or just "julia" if system-wide installed
#I am using 1.6.5
JULIA_BINARY = path_to_julia_binary

#specify the number of bootstrap replicates
NREPS = 100

#paths to software or just the binaries if already in your path
HMAX = 1
NRUNS = 20
OUTPUT_SUFFIX = snaq
NPROCS = 1
STARTING_TREE = full_path_to_starting_tree_file/mytree.tre
MAPPING_FILE = full_path_to_mapping_file/manyalleles.spMap

#Should both loci and trees within loci be resampled (0 = trees only || 1 = trees and loci)
RESAMPLE_LOCI = 1
