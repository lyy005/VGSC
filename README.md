# step 1 - trimmomatic filtering
First, we trimmed sequencing adapters 

```
java -jar trimmomatic-0.39.jar PE -phred33 HO.1.fastq.gz HO.2.fastq.gz HO.pe.1.fq HO.se.1.fq HO.pe.2.fq HO.se.2.fq ILLUMINACLIP:combined_adaptors.fa:2:30:10:8:TRUE LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 -threads 10
```

# step 2 - Trinity assembly
Secondly, Trinity was used to assemble the transcriptome
```
singularity exec -e trinityrnaseq.v2.15.2.simg Trinity --seqType fq --left `pwd`/HO_pe.1.fq.gz --right `pwd`/HO_pe.2.fq.gz --max_memory 200G --CPU 45 --output `pwd`/HO_trinity/
```

# pick the longest isoform from Trinity assembly
perl pick_longest_isoform.pl HO.trinity.fasta HO.trinity.fasta.longest

# BLAST to reference sodium channel genes
blastx -query HO.trinity.fasta.longest -db para.rename.pep.fas -outfmt '6 qaccver qlen qcovs saccver slen pident length mismatch gapopen qstart qend sstart send evalue bitscore' -out HO.trinity.fasta.longest.blastx -evalue 1e-10


awk '($2>1000)&&($3>=50){print $1}' HO.trinity.fasta.longest.blastx | sort | uniq > HO.trinity.fasta.longest.blastx.namelist
perl pick_sequences_on_list.pl HO.trinity.fasta.longest HO.trinity.fasta.longest.blastx.namelist HO.trinity.fasta.longest.blastx.namelist.fasta

# use Exonerate to annotate the genes, based on Bombyx mori sodium channel gene
exonerate -q Bmori.fas -t HO.trinity.fasta.longest.blastx.namelist.fasta --showtargetgff yes -m protein2dna -E > HO.trinity.fasta.longest.blastx.namelist.fasta.gff
grep "similarity" HO.trinity.fasta.longest.blastx.namelist.fasta.gff > HO.trinity.fasta.longest.blastx.namelist.fasta.gff2
perl Gff2sequence.pl HO.trinity.fasta.longest.blastx.namelist.fasta HO.trinity.fasta.longest.blastx.namelist.fasta.gff2 HO.Nav.fas
