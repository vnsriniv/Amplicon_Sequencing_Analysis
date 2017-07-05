#This code converts the MiDAS file which is QIIME format to mothur format. It deletes the species assignment, deletes the k__, p__, etc from the taxonomic assignments. 
#!/bin/bash
file="MiDAS_S123_2.1.3.tax" #file name
while IFS=$'\t;' read -r seqid kingdom phylum class order family genus species ; do #Set IFS to tab and ; and read in each line and separate the fields based on IFS and store in variables
	echo -e "$seqid\t${kingdom#*__};${phylum#*__};${class#*__};${order#*__};${family#*__};${genus#*__};" >> ${HOME}/mothur/midas_mothur.tax #Peform necessary manipulations and write it into a file
done < $file #Use the file as the input for the while loop.
