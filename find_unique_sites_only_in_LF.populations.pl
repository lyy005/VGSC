#!usr/bin/perl -w
use strict;

die "Usage: perl $0 [.fa] [list of spp (separated by comma)] [out.fa]
 Explainations: 
  1. the amino acid has to be the same in the list of resistant spp
  2. the position cannot be gap
  3. none of the non-resistant spp should share the resistant amino acid in that position
" unless (@ARGV == 3);
open (FA, $ARGV[0]) or die "$ARGV[0] $!\n";
open OUT, ">$ARGV[2]" or die "$ARGV[2] $!\n";
open OUT2, ">$ARGV[2].variation_in_resis" or die "$ARGV[2].variation_in_resis $!\n";

my $spp = $ARGV[1];
my @spp = split/\,/, $spp;

my %resis;
foreach my $i (@spp){
	$resis{$i} = 1;
}

print "@spp\n"; 

$/=">";
<FA>;

my @comp;
my @resis_comp;
my $resis_seqcount = 0;
my $seqcount = 0;
my $bpcount = 0;

my @resis_spp_order;
my @spp_order;

while(<FA>){
	chomp;
	my $line = $_;
	my @line = split/\n+/, $line;
	my $name = shift @line;
	my $seq = join "", @line;

	# save the resistant seqs
	if($resis{$name}){
		print "Resistant spp: $name\n";
		push @resis_spp_order, $name;
		my @seq = split/\s*/, $seq;
		$bpcount = 0;
		foreach my $k (@seq){
			$resis_comp[$bpcount][$resis_seqcount] = $k;
			$bpcount ++;
		}
		$resis_seqcount ++;
	}else{
		push @spp_order, $name;
		my @seq = split/\s*/, $seq;
		$bpcount = 0;
		foreach my $k (@seq){
			$comp[$bpcount][$seqcount] = $k;
			$bpcount ++;
		}
		$seqcount ++;
	}
}
close FA;

# 1 - make concensus of the resistant spp
print OUT " @resis_spp_order\t@spp_order\n";
print OUT2 " @resis_spp_order\t@spp_order\n";

foreach my $i (0..$#resis_comp){
	#print OUT "$i\t";

	# make a hash to count the number of amino acid kinds
	my %resis_consensus;

	# make concensus
	foreach my $j (0..$#{$resis_comp[$i]}){
		#print OUT "$resis_comp[$i][$j] ";
		if($resis_consensus{$resis_comp[$i][$j]}){
			$resis_consensus{$resis_comp[$i][$j]} ++;
		}else{
			$resis_consensus{$resis_comp[$i][$j]} = 1;
		}
	}

	my @types = keys %resis_consensus;
	my $types = join " ", @types;

	# record all AAs of resistant spp
	my @resis_line = @{$resis_comp[$i]};
	my $resis_output = join " ", @resis_line;

	# record all AAs of non-resistant spp
	my @line = @{$comp[$i]};
	my $output = join " ", @line;

	if(scalar @types == 1){
		if($types !~ /\-/){
			#print OUT "$i\t$resis_output\t\t$output\n";
			
			# find unique substitutions to resistant spp
			if($output =~ /$types/){
				print OUT2 "$i\t$resis_output\t\t$output\tresis_match_non_resis_AAs\n";
			}elsif($output =~ /\-/){
				print OUT2 "$i\t$resis_output\t\t$output\tnon_resis_match_gap\n";
			}else{
				print OUT "$i\t$resis_output\t\t$output\n";
			}

		}else{
			print OUT2 "$i\t$resis_output\t\t$output\tresis_match_gap\n";
		}
	}else{
		print OUT2 "$i\t$resis_output\t\t$output\tresis_multiple_AAs\n";
	}
}

##print OUT "\tLF\tBmori\tDmel\tHousefly\tTcast\tHO\tPL\tPR\tLlun\tAsp\n";
#print OUT "loci\tvar\n";
#foreach my $i (0..$#comp){
#	my $repre = $comp[$i][0];
#	my $flag = 1;
#	my %hash;
#	$hash{$lf[$i]} = 1 if $lf[$i] ne "-";
#print "\n$lf[$i]\t";
#	print OUT "$i\t$lf[$i]\t";
#	foreach my $j (0..$#{$comp[$i]}){
#print "$comp[$i][$j]\t";
##		print OUT "$comp[$i][$j]\t";

#		if($comp[$i][$j] eq "-"){
			
#		}elsif($repre eq $comp[$i][$j]){
#			$hash{$comp[$i][$j]} ++;
#		}else{
#			$hash{$comp[$i][$j]} ++;
#			$flag = 0;
#		}
#	}
#	my $kinds = keys %hash;
#	print OUT "$i\t$kinds\n";
##	print OUT "\n";
#	if(($flag == 1)&&($repre ne $lf[$i])&&($lf[$i] ne "-")){
#		print "$i\n";
#	}
#}
#close OUT;
print "DONE!
Output files:
 $ARGV[2]
 $ARGV[2].variation_in_resis
";
