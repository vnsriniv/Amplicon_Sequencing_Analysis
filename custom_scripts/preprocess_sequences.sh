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


