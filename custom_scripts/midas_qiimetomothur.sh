#This code converts the MiDAS file which is QIIME format to mothur format. It deletes the species assignment, deletes the k__, p__, etc from the taxonomic assignments. 
#!/bin/bash

sed -r 's/\<[kpcofgs]__//g' MiDAS_S123_2.1.3.tax | sed -r 's/;[^;]+$|;;+/;/' > MiDAS_S123_2.1.3.mothur.tax
