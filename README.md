# 1 - Trimmomatic filtering
First, we trimmed sequencing adapters 

```
java -jar trimmomatic-0.39.jar PE -phred33 HO.1.fastq.gz HO.2.fastq.gz HO.pe.1.fq HO.se.1.fq HO.pe.2.fq HO.se.2.fq ILLUMINACLIP:combined_adaptors.fa:2:30:10:8:TRUE LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 -threads 10
```

# 2 - Trinity assembly
Secondly, Trinity was used to assemble the transcriptome
```
singularity exec -e trinityrnaseq.v2.15.2.simg Trinity --seqType fq --left `pwd`/HO_pe.1.fq.gz --right `pwd`/HO_pe.2.fq.gz --max_memory 200G --CPU 45 --output `pwd`/HO_trinity/
```

# 3 - Annotation using Trinotate
To annotate protein-coding genes, Trinotate was used to find potential open reading frames in Trinity assemblies. 
```
singularity exec -e transdecoder.v5.7.1.simg TransDecoder.LongOrfs -t HO.fasta --output_dir ./
singularity exec -e transdecoder.v5.7.1.simg TransDecoder.Predict -t HO.fasta
```

# 4 - Sodium channel gene annotation based on BLASTP
Align annotated genes to reference sodium channel protein sequences. 
```
blastp -db outgroup_sodium_channel.pep -query LF.fasta.transdecoder.pep -outfmt "6 qlen slen qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore" -evalue 1e-5 -num_threads 5 -out LF.outgroup.blast
blastp -db outgroup_sodium_channel.pep -query LF_longest.pep -outfmt "6 qlen slen qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore" -evalue 1e-10 -num_threads 1 -out LF_longest.pep.blast
```

# 5 - Search for amino acid replacements related to resistance
Criteria: 
a. The amino acid has to be the same in the list of resistant species
b. The position cannot be gaps
c. None of the non-resistant spp should share the resistant amino acid in that position

```
perl find_unique_sites_only_in_LF.populations.pl combined_outgroup.renamed.faa.aln LF_TRINITY_DN616_c0_g1_i11.p1,LiFl_CF_20_TRINITY_DN2854_c0_g1_i14.p1,LiFl_CF_27_TRINITY_DN1074_c0_g1_i2.p1,LiFl_CF_36_TRINITY_DN1157_c0_g1_i4.p1 test.out
```

# 6 - SNV-calling
Make super-transcripts and call SNVs on the super-transcripts
```
singularity exec -e trinityrnaseq.v2.15.2.simg /usr/local/bin/Analysis/SuperTranscripts/Trinity_gene_splice_modeler.py --trinity_fasta LF_trinity.Trinity.fasta --incl_malign
samtools faidx trinity_genes.fasta
singularity exec -e trinityrnaseq.v2.15.2.simg /usr/local/bin/Analysis/SuperTranscripts/AllelicVariants/run_variant_calling.py --st_fa trinity_genes.fasta --st_gtf trinity_genes.gtf -p LF_pe.1.fq.gz LF_pe.2.fq.gz -o variant_calls_outdir --threads 20 --maxram 212085784160
```

# 7 - Species identification
MitoZ (https://github.com/linzhi2013/MitoZ) was used to extract the COX1 genes from transcriptome data: 
For the LF sample, 5G of data was used:
```
singularity run MitoZ_v3.6.sif mitoz all --fq1 pe.1.fq.gz --fq2 pe.2.fq.gz --outprefix mitoz --thread_number 40 --workdir ./ --clade Arthropoda --requiring_taxa Arthropoda --assembler spades --memory 100 --data_size_for_mt_assembly 5,0
```

For the other samples, 2G of data was used:
```
singularity run MitoZ_v3.6.sif mitoz all --fq1 pe.1.fq.gz --fq2 pe.2.fq.gz --outprefix mitoz --thread_number 40 --workdir ./ --clade Arthropoda --requiring_taxa Arthropoda --assembler spades --memory 100
```
