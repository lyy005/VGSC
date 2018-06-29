#!usr/bin/perl -w
use strict;

die "Usage: perl $0 [trinity.fa] [out.fa]\n" unless (@ARGV == 2);
open (FA, $ARGV[0]) or die "$ARGV[0] $!\n";
open OUT, ">$ARGV[1]" or die "$ARGV[1] $!\n";

my (%len, %longest);
$/=">";
<FA>;
while(<FA>){
	chomp;
	my @line = split /\n+/;
	my $name = shift @line;
	my $seq = join "", @line;

	my @name_line = split /\s+/, $name;
	my @name = split/\_/, $name_line[0];
	my $gene = $name[0]."_".$name[1]."_".$name[2]."_".$name[3];

	my $length = $name[1];
	$length = length ($seq);

#print "### $name\n### $length\n"; 

	if($len{$gene}){
		if($length > $len{$gene}){
			$len{$gene} = $length;
			$longest{$gene} = ">".$name_line[0]."\n".$seq."\n";
		}
	}else{
		$len{$gene} = $length;
		$longest{$gene} = ">".$name_line[0]."\n".$seq."\n";
	}
}
close FA;

foreach my $k (sort keys %len){
	print OUT "$longest{$k}";
}
close OUT;
print "DONE!";
