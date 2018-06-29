# trimmomatic filtering
java -jar trimmomatic-0.32.jar PE -threads 8 -trimlog trimmomatic.log -phred33 Hesperophylax-occidentalis.1.fastq.gz Hesperophylax-occidentalis.2.fastq.gz HO.pe.1.fq HO.se.1.fq HO.pe.2.fq HO.se.2.fq ILLUMINACLIP:MiSeq.adapter.fas:2:30:10:8:true LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:40

# combine single ended reads with pair ended reads for trinity assembly
less -S HO.pe.1.fq | perl -e 'while(<>){chomp; @name=split; $seq = <>; $plus = <>; $qual = <>; print "$name[0]/1\n$seq$plus$qual";}' > HO.trinity.1.fq
less -S HO.pe.2.fq | perl -e 'while(<>){chomp; @name=split; $seq = <>; $plus = <>; $qual = <>; print "$name[0]/2\n$seq$plus$qual";}' > HO.trinity.2.fq
less -S HO.se.1.fq | perl -e 'while(<>){chomp; @name=split; $seq = <>; $plus = <>; $qual = <>; print "$name[0]/1\n$seq$plus$qual";}' >> HO.trinity.1.fq
less -S HO.se.2.fq | perl -e 'while(<>){chomp; @name=split; $seq = <>; $plus = <>; $qual = <>; print "$name[0]/1\n$seq$plus$qual";}' >> HO.trinity.1.fq

# trinity assembly
Trinity --seqType fq --max_memory 10G --left HO.trinity.1.fq --right HO.trinity.2.fq --CPU 16 --output HO_trinity

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
