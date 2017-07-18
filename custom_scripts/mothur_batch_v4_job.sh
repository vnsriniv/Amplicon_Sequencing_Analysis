#!/bin/bash
# BATCH MODE SETTINGS -- below lines works only with SLURM (batch mode). If running on your own computer, just ignore them.
#SBATCH --job-name=mothur_batch_v4_script_run
#SBATCH --error=mothur_batch_v4_script_run.error
#SBATCH --time=480
#SBATCH --partition=ser-par-10g-2
#SBATCH --cpus-per-task=32
#SBATCH --nodes=1
# defining working directory here
#SBATCH --workdir=/scratch/vnsriniv/
#SBATCH --exclusive
# END OF BATCH MODE SETTINGS

# below are mothur script customizing settings
# change directories/file here
# working directory
# mothur input directory
input_dir="/scratch/vnsriniv/RC_input_files" #have to add full directory path
# mothur output directory
output_dir="/scratch/vnsriniv/RC_midas_sansPrecluster_run" #supply full directory path
# mothur log file
log_file="RC_midas_sansPrecluster_run_log"
# use number of threads; cannot exceed -c # or -n # defined above
num_threads="32"

# mothur contig file, this should be generated in former step
contig_file="mothur.batch.files.txt"
# alignment database
align_ref="silva.nr_v123.v4.align"
# classify databse; make sure that the _ref and _tax file are part of the same database
classify_ref="MiDAS_v123_2.1.3.fasta"
classify_tax="MiDAS_v123_2.1.3.mothur.tax"
# end of customizing
###########################################################################################
# anything below should be fine without changing
# make sure all files exist
CheckFile()
{
	echo -n "checking $1 .. "
	if [[ (-f $1) || (-f $input_dir/$1) ]]; then
		echo "OK"
	else
		echo "FAIL (can't find such file)"
		exit 1
	fi
}

CheckFile $contig_file
CheckFile $align_ref
CheckFile $classify_ref
CheckFile $classify_tax

# customize mothur script
ReplaceVariable()
# ReplaceVariable <file> <replace_var> <to_text>
{
	# to deal with the replacement, the most difficults are:
	# 1) '\' in perl regex
	# 2) '/' in perl regex
	# solution:
	# 1) '\' -> '\\' >> '\\' -> '\\\\' (do first)
	# 2) '/' -> '\/' >> '\/' -> '\\\/' (then deal with this)
	t=$(echo $3 | sed 's/\\/\\\\/g' | sed 's/\//\\\//g')
	sed -i "s/$2/$t/g" $1
}

echo "configuring mothur script .."
cp mothur_batch_v4_script.template mothur_batch_v4_script.txt
ReplaceVariable mothur_batch_v4_script.txt '\$input_dir\$' $input_dir
ReplaceVariable mothur_batch_v4_script.txt '\$output_dir\$' $output_dir
ReplaceVariable mothur_batch_v4_script.txt '\$log_file\$' $log_file
ReplaceVariable mothur_batch_v4_script.txt '\$num_threads\$' $num_threads
ReplaceVariable mothur_batch_v4_script.txt '\$contig_file\$' $contig_file
ReplaceVariable mothur_batch_v4_script.txt '\$align_ref\$' $align_ref
ReplaceVariable mothur_batch_v4_script.txt '\$classify_ref\$' $classify_ref
ReplaceVariable mothur_batch_v4_script.txt '\$classify_tax\$' $classify_tax

echo "running mothur .."
mothur mothur_batch_v4_script.txt
