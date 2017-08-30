---
layout: page
title: A tutorial for 16S rRNA gene amplicon sequencing analysis
modified: July 18th 2017
excerpt: "Created by Varun Srinivasan, Contributor: Guangyu Li"
comments: true
---

{% include _toc.html %}

This is an attempt to put together a comprehensive tutorial for amplicon sequencing analysis. This is meant to get people new to amplicon sequencing analysis started. Modifications to the code will be required if you need to do anything more than the basic analysis.

Before you tackle this tutorial, you need to have a basic knowledge of the Unix Shell and bash. You don't need to master all these tutorials, but you should attempt to go through them atleast once before you tackle the rest of this tutorial.

- [Unix Shell by swcarpentry](http://swcarpentry.github.io/shell-novice/)
- [Command Line by Code Academy](https://www.codecademy.com/learn/learn-the-command-line/)

# Software Installation Instructions
You are going to need the following software to run this analysis.

## FastQC
FastQC is a convenient software to check the quality of your reads. It is a java based application. So you need to make sure your system contains java. Check the install.txt file for instructions once you download the zip file and unzip it.

```bash
cd ${HOME}
#Download FastQC
wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip
#Unzip
unzip fastqc_v0.11.5.zip && cd FastQC
#Change permissions to make it executable
chmod 755 fastqc
#Create symbolic link in the local bin folder. Now you can just use the command fastqc from any directory
if [[ ! -d ${HOME}/bin ]]; then mkdir ${HOME}/bin; fi
ln -s ${HOME}/FastQC/fastqc ${HOME}/bin/fastqc
```
## Sickle
Sickle is a quality-trimming software that can be used to trim your sequences to a minimum quality score. Sickle can be downloaded from the github page [https://github.com/najoshi/sickle].

```bash
cd ${HOME}
#Download sickle. Update the v1.33 with the latest version number from the github page.
wget -O sickle.zip https://github.com/najoshi/sickle/archive/v1.33.zip
#Unzip. If you are downloading a different version than 1.33 then the code will require modification.
unzip sickle.zip && cd sickle-1.33
#Compile source code
make
#Change permissions
chmod 755 sickle
#Check if sickle is successfully built. If correctly done, the sickle version and developer information will be displayed
./sickle --version
#Create symbolic link in the local bin folder.
if [[ ! -d ${HOME}/bin ]]; then mkdir ${HOME}/bin; fi
ln -s ${HOME}/sickle-1.33/sickle ${HOME}/bin/sickle
```

## Mothur
Installing mothur is pretty easy. It comes precompiled as executable files.

```bash
cd ${HOME}
#Download mothur
wget -O Mothur.linux_64.zip https://github.com/mothur/mothur/releases/download/v1.39.4/Mothur.linux_64.zip
#unzip
unzip ../Mothur.linux_64.zip
#Add mothur to your path variable
export PATH=$PATH:${HOME}/mothur
#Create symbolic link
cd mothur
if [[ ! -d ${HOME}/bin ]]; then mkdir ${HOME}/bin; fi
for i in $(ls -1); do ln -s -T ${HOME}/mothur/$i ${HOME}/bin/$i; done
```

# Reference Databases
We will now download reference databases that are required for amplicon sequencing analysis.
## Silva
The [SILVA database](https://www.arb-silva.de/) is a comprehensive online, quality-checked database of aligned SSU  and LSU  rRNA sequences. The database needs a little bit of tweaking before it is compatible with mothur. The tweaked database is shared by the mothur creators [here](https://www.mothur.org/wiki/Silva_reference_files) (If you are interested in the steps to tweak the original database, see this [README](http://blog.mothur.org/2017/03/22/SILVA-v128-reference-files/) file posted by Pat Schloss). At the time of writing this tutorial, the latest version is Release 128. However we will still use v123 since the MiDAS database which we will also use was created using the v123. If you need the latest version of SILVA (v128) just head to the link given above and download it.

```bash
#Download the files
wget https://www.mothur.org/w/images/b/be/Silva.nr_v123.tgz
#unzip
tar -xzvf Silva.nr_v123.tgz
```

## MiDAS Taxonomy
The [MiDAS:Field Guide](http://www.midasfieldguide.org/) was created [McIlroy et al(2015)](http://database.oxfordjournals.org/content/2015/bav062.full?sid=6829f12b-4ae3-4258-acbe-d437059d55ac). This is a online resource that aims to help researchers and operators identify microorganisms relevant to wastewater treatment and understand their role. As part of this project, the researchers have also created the MiDAS taxonomy which is a manual curation of the SILVA taxonomy. The available version as of July 2017 is curated from [SILVA v123](https://www.arb-silva.de/documentation/release-123/).

The MiDAS taxonomy comes formatted for QIIME but not mothur. I have formatted the QIIME version to mothur format and will provide the files.

<mark>In case you are interested I created a script to format the taxonomy file to the mothur format- [MiDAS_qiimetomothur.sh](https://github.com/vnsriniv/Amplicon_Sequencing_Analysis/blob/master/custom_scripts/midas_qiimetomothur.sh) and use the script to format it to mothur.
You can download the MiDAS files from the [MiDAS:Field Guide](http://www.midasfieldguide.org/) website- [MiDAS_S123_2.13](http://midasfieldguide.org/download/midas_v2_13/midas_s123_213tar.gz). I would check on the website first to make sure this is the latest version. </mark>


Now we have installed all necessary softwares and downloaded all required files. Let us proceed with some preprocessing steps and the actual analysis.
# Create Custom Alignment Database
We will first customize the SILVA database to our region of interest (V4). This is mainly to reduce computational memory and time required during our downstream analysis.

```bash
#Start mothur by just typing in mothur in the command line
mothur
```
If you see the output that ends with "mothur > " this means you are in the mothur command line. All mothur commands will work now. If you need to execute some unix commands from inside mothur, you can use the function system() and enclose your unix commands inside the brackets.

The command for performing a in-silico pcr is pcr.seqs. We will use the start and end parameter to specify the region of interest. This has been pre-determined for V4 sequencing.
```bash
pcr.seqs(fasta=silva.nr_v123.align, start=13862, end=23444, keepdots=F, processors=5)
#Rename the pcr file
system(mv silva.nr_v123.pcr.align silva.nr_v123.v4.align)
```
Next step is to preprocess our sequences to prepare them for mothur analysis.

# Preprocess Sequences
The folder organization for using this code is : create a folder called "seq_analysis" in your home directory.Inside that transfer the project folder from Illumina basespace. Inside the project folder, there should be folders for each sample within which there are the forward and reverse reads. Here is an example folder organization

![Folder_Organization](folder_org.png)

Transfer the "preprocess_sequences.sh" into the your working directory (for example: seq_analysis). This folder will also contain the project folder "ProjectName" (For example: TookerS2EBPR).

The preprocessing steps are a little complicated, mainly because when the sequences come from the Illumina Basespace website, they have a lot of random numbers and letters associated with them. We want to change all the folder names and file names to something that is relevant to our analysis. I have only tested this on one dataset. We will have to see if we perform another sequencing run with UConn-MARS, if the dataset will look similar. Also if you perform sequencing with some other company, the data will probably look very different.

In this section of tutorial, we will perform the following steps:
1. Change the name of the files.
2. Decompress .fastq.gz files into fastq files.
3. Create symbolic links in a separate fastq folder for quality checking by combining all the forward reads and combining all the reverse reads.
4. Create FASTQC reports.
5. Perform sickle quality filtering on the fastq files in the sample folders, output files with same file name but with a prefix of "q".
6. Create a batch file for mothur in the bash script.
7. Create symbolic links for the quality-filtered files in a separate folder outside of the native folder organization.

All these steps will be accomplished by a script called "preprocess_sequences.sh". The ".sh" implies that it is a shell script. You will have to make some changes to the script. Here is the script (you don't have to copy paste anything. We will run the script directly from the file. Just copy the script file to your working directory)

In this script, there is a block of code (which is enclosed between lines of ###). This is the section you will have to change.

- Depending on your directory path, change ```"wdir=${HOME}/seq_analysis"``` to ```"wdir=your_working_directory"```.

- In the Discovery cluster, there is a folder called scratch where all temporary input files and output files can be stored. I usually like to create a folder called input_files (where I will keep all the files that mothur requires) and output_files (where I will store all the files that mothur generates). Depending on what the name and location of the input_files folder is , you should change ```"inputdir=/scratch/vnsriniv/input_files_test/"``` to ```"inputdir=your_input_directory"```

```Note: Always assume that anything on the cluster is not safe. So you should backup all the file locally on your computer. ```

```bash
cd seq_analysis
#We will first change a couple of things in the preprocess_sequences.sh file
vi preprocess_sequences.sh
```
Now the script will look like this.

```You will have to know how to use the vi editor. Familiarize yourself with some basic commands to use in vi. This is important. ```

```bash
#!/bin/bash

#The folder organization for using this code is : create a folder called mothur in your home directory. Inside that transfer the project folder from Illumina basespace to the mothur folder. Inside the project folder, there should be folders for each sample within which there are the forward and reverse reads.

#All the operations performed here are from the project directory. So navigate first to the project directory before running this script

#################CHANGE THIS####################################
wdir=${HOME}/seq_analysis
inputdir=/scratch/vnsriniv/input_files_test/
################################################################

#Create necessary folders
parent=`pwd`	#Store the project directory
mkdir ${wdir}/fastqc_files/	#Create a folder for fastqc

#Remove -randomnumber from folder names
for folder in *; do
	mv $folder ${folder%-*}; #Remove - and following characters from end of folder name
done

#Change .fastq.gz file names into foldername_R1/R2.fastq.gz
subdirs=`ls $parent`	#Store the names of all sample folders
for foldername in $subdirs; do
	files=`ls ${parent}/${foldername}/`	#Store the names of files inside the sample folder
	for filename in $files; do
		name=${filename%.fastq.gz}	#store the filename without the extension
		name2=${name#*L001_}	#Remove everything including and upto L001_ from the front
		name3=${name2%_001*}	#Remove everything and after _001 from the back
		newfilename=${foldername}_${name3}.fastq.gz	#Attach the foldername to R1/R2 and create new file name
		mv ${parent}/${foldername}/$filename ${parent}/${foldername}/$newfilename #Rename the old file with the new file name
		gunzip -d ${parent}/${foldername}/$newfilename #Decompress the fastq.gz file to fastq
		ln -s ${parent}/${foldername}/${newfilename%.fastq.gz}.fastq ${wdir}/fastqc_files/${newfilename%.fastq.gz}.fastq
	done
done

#Create FASTQC Reports. This assumes that you have installed FASTQC and have created a system path in /bin folder

#First concatenate all the forwards and reverse reads. Remove all the symbolic links.
cat ${wdir}/fastqc_files/*R1.fastq> ${wdir}/fastqc_files/forward_reads.fastq
cat ${wdir}/fastqc_files/*R2.fastq> ${wdir}/fastqc_files/reverse_reads.fastq
rm ${wdir}/fastqc_files/*R1.fastq
rm ${wdir}/fastqc_files/*R2.fastq
#Run FASTQC
fastqc ${wdir}/fastqc_files/forward_reads.fastq -o ${wdir}/fastqc_files/
fastqc ${wdir}/fastqc_files/reverse_reads.fastq -o ${wdir}/fastqc_files/
module load sickle/1.33
subdirs=`ls $parent`	#Store the names of all sample folders
for foldername in $subdirs; do
	forward=`ls ${parent}/${foldername}/*R1.fastq`	#Store the forward read file name
	reverse=`ls ${parent}/${foldername}/*R2.fastq`	#Store the reverse read file name
	sickle pe -f ${forward}  -r ${reverse} -t sanger -o ${parent}/${foldername}/q$(basename $forward) -p ${parent}/${foldername}/q$(basename $reverse) -s ${parent}/${foldername}/${foldername}_unpaired.fastq -q 20
done

#Create the mothur batch file
touch ${inputdir}/mothur.batch.files.txt
for foldername in $subdirs; do
	forward=`ls ${parent}/${foldername}/q*R1.fastq`	#Store the forward quality-filtered read file name
	reverse=`ls ${parent}/${foldername}/q*R2.fastq`	#Store the reverse quality-filtered read file name
	echo -e "$foldername\t$(basename $forward)\t$(basename $reverse)" >> ${inputdir}/mothur.batch.files.txt
done

#Copy all quality-filtered files to mothur folder
for foldername in $subdirs; do
	cp ${parent}/${foldername}/q*R* ${inputdir}/
done
```


After this is done, we can now run perform the preprocessing. **Make sure you are inside the project directory (in this case: TookerS2EBPR) before performing this operation.

```bash
bash ../preprocess_sequences.sh
```
This will take a while. As long as you don't see any error/warning messages, sit back and relax (or read a paper!!)

Once it is done, we should be ready to mothur these sequences!

# Mothur analysis
Most of the steps in this tutorial is from the [MiSeq SOP](https://www.mothur.org/wiki/MiSeq_SOP). I am repeating it here for convenience. But you should follow the MiSeq SOP so that you clearly understand each step and the choice of parameters!

Before you perform the following analysis, I would suggest you make sure all this analysis works by executing each step on a subset of your full analysis. I usually like to chose 2-4 samples to run the analysis on step by step and then perform a batch analysis for the whole dataset. If you have already done that, you can skip to the "Batch Analysis" section.

Below is a mothur script template. Note that this script cannot be run directly as-is. This script, however, will be run by another script called mothur_batch_v4_job.sh (which is shown in the next section).  If you want to change the workflow, you can modify the mothur_batch_v4_script.txt file. The script is not very well annotated because I probably won't do as good a job as the [MiSeq SOP](https://www.mothur.org/wiki/MiSeq_SOP) has done. So please refer to the SOP for any information.

```text
#mothur_batch_v4_script.template
#this is a template for mothur scripts, cannot be run directly; run mothur_batch_v4_job.sh instead!
set.dir(input=$input_dir$, output=$output_dir$)
set.logfile(name=$log_file$)
#Make contigs from paired end sequences
make.contigs(file=$contig_file$, processors=$num_threads$)
summary.seqs(fasta=current)
screen.seqs(fasta=current, group=current,summary=current,maxambig=0, maxlength=275,minlength=225)
unique.seqs(fasta=current)
count.seqs(name=current,group=current)
summary.seqs(count=current)
align.seqs(fasta=current,reference=$align_ref$, flip=t)
summary.seqs(fasta=current,count=current)
screen.seqs(fasta=current,count=current,summary=current,start=8, end=9582, maxhomop=8)
summary.seqs(fasta=current, count=current)
filter.seqs(fasta=current, vertical=T,trump=.)
unique.seqs(fasta=current, count=current)
pre.cluster(fasta=current, count=current, diffs=2)
chimera.uchime(fasta=current,count=current, dereplicate=t)
remove.seqs(fasta=current,accnos=current)
classify.seqs(fasta=current, count=current, reference=$classify_ref$, taxonomy=$classify_tax$, cutoff=80)
remove.lineage(fasta=current, count=current,taxonomy=current,taxon=Chloroplast-Mitochondria-unknown-Eukaryota)
cluster.split(fasta=current, count=current,taxonomy=current, splitmethod=classify, taxlevel=4, cutoff=0.03)
make.shared(list=current, count=current, label=0.03)
classify.otu(list=current, count=current, taxonomy=current, label=0.03)
count.groups(shared=current)
```
## Running mothur in batch mode
Below is the mothur_batch_v4_job.sh file. In this file, the input and output directory and the logfile name can be changed to whatever you want. Also you can use any mothur contig file or databases for analysis. In addition, no.of processors can also be configured to the no.of cores in the node, just make sure the no. of processors defined by 'cpus-per-task' and
'num_threads' are consistant, and not exceed the actual no. of threads physically owned by your machine.

```bash
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
```

For running this script, simply run

```bash
bash mothur_batch_v4_job.sh
```

This code will check the existance of all necessary files, configure the mothur script and finally run mothur. If any of the required files are missing, the execution will terminate. Though not necessary, it is recommended to run this script from the project directory as a good practice.
Note that the lines start with #SBATCH work only when you run this script in batch mode on a server which uses a SLURM job manager. Otherwise (e.g. on your local machine), these lines are ignored.

# Downstream Analysis
Now that we have the OTU table and taxonomic classification for the OTUs, the next step is to perform downstream analysis of this data to create figures and perform statistical tests. Since this is extremely dependent on your experiment and the particular hypotheses you are testing, I will only include a few resources for microbial ecology analysis in R for you to go through.

```Note: There are many packages and platforms for you to perform your analysis in R. I will highlight a few that I have used before and some general resources for R. In the end, it is your choice and perference that will dictate which ones you use.```

## General R Tutorials
- [Programming with R](http://swcarpentry.github.io/r-novice-inflammation/)
- [R for Reproducible Scientific Analysis](http://swcarpentry.github.io/r-novice-gapminder/)

## Tidyverse Tutorial
Tidyverse is a set of R packages designed for easy data manipulation and analysis. I have found that use of these packages makes code more readable and easy to follow (both for your future-self and for others).
- [General Tidyverse Tutorial](http://www.fabianheld.com/r-tidyverse/)
- [ggplot 2 Tutorial](http://tutorials.iq.harvard.edu/R/Rgraphics/Rgraphics.html#org93999d8)

## Microbial Ecology Tutorials
Here is a list of packages for Microbial Ecology Analysis using R with tutorials.
- [Ampvis](http://madsalbertsen.github.io/ampvis/examples/ampvis_guide.html)
- [Phyloseq](https://joey711.github.io/phyloseq/import-data.html)

Here is a Microbial Informatics course material that Pat Schloss has posted which covers best practices for reporoducible research and statistical analyses in R.
- [Microbial Informatics](http://microbialinformatics.github.io/)
