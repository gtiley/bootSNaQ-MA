#!/usr/bin/perl -w
use strict;

#----------------------------------------------------------------------------------------#
#George P. Tiley
#7 June 2022
#contact: g.tiley@kew.org
#wrapper to distribute SNaQ jobs for bootstrap trees
#takes SNaQ arguments from the control file and generates Julia scripts
#executes Julia scripts on some computing system cloud or local with a generic template file
#option for between species only or between and within species quartet sampling
#option for sampling bootstrap trees from loci only or sampling loci + bootstrap trees
#assumes bootstrap trees are all in one file, line-by-line, in newick format. This is provided by most programs. Nexus formats will cause problems.
#----------------------------------------------------------------------------------------#

# Accepted AND necessary commands
my @checkArgs = ("controlFile","template","runmode");
my %passedArgs = ();
if (scalar(@ARGV) == 0)
{
die "/*--------INPUT PARAMETERS--------*/\n
--controlFile STRING <control file>
--template STRING <template file for distributing on a cluster>
--runmode INT <0 = between species quartets only || 1 = between and within species quartets || 2 = collect best bootstrap networks for downstream analysis>

\n/*--------EXAMPLE COMMAND--------*/\n
perl bootSNaQ-MA.pl --controlFile parameters.ctl --template template.sh --runmode 0\n
	
\n/*--------NOTES--------*/\n
For regular bootstrapping analyses, see the bootsnaq program in PhyloNetworks\n";
}

elsif (scalar(@ARGV) > 0)
{
    for my $i (0..(scalar(@ARGV) - 1))
    {
		if ($ARGV[$i] eq "--controlFile")
		{
	    	$passedArgs{controlFile} = $ARGV[$i+1];
		}
		if ($ARGV[$i] eq "--runmode")
		{
	    	$passedArgs{runmode} = $ARGV[$i+1];
	    	if (($passedArgs{runmode} != 0) && ($passedArgs{runmode} != 1) && ($passedArgs{runmode} != 2))
	    	{
	    		die ("--runmode must be either 0 or 1 or 2\n")
	    	}
		}
		if ($ARGV[$i] eq "--template")
		{
        	$passedArgs{template} = $ARGV[$i+1];
		}
	}
	foreach my $arg (@checkArgs)
	{
		if (! exists $passedArgs{$arg})
		{
	    	die "/*--------MISSING PARAMETER--------*/\nMissing command line argument: $arg\n\n";
		}
	}
}

my %controlArgs = ();
open FH1,'<',"$passedArgs{controlFile}";
while (<FH1>)
{
	if (/BOOTSTRAP_DIR\s+\=\s+(\S+)/)
    {
		$controlArgs{BOOTSTRAP_DIR} = $1;
    }
	if (/BOOTSTRAP_SUFFIX\s+\=\s+(\S+)/)
    {
		$controlArgs{BOOTSTRAP_SUFFIX} = $1;
    }
    if (/SNAQ_OUTPUT\s+\=\s+(\S+)/)
    {
		$controlArgs{SNAQ_OUTPUT} = $1;
		system "mkdir $controlArgs{SNAQ_OUTPUT}";
    }
    if (/SCHEDULER\s+\=\s+(\S+)/)
    {
        $controlArgs{SCHEDULER} = $1;
    }
    if (/JULIA_BINARY\s+\=\s+(\S+)/)
    {
        $controlArgs{JULIA_BINARY} = $1;
    }
    if (/NREPS\s+\=\s+(\S+)/)
    {
        $controlArgs{NREPS} = $1;
    }
    if (/HMAX\s+\=\s+(\S+)/)
    {
        $controlArgs{HMAX} = $1;
    }
    if (/NRUNS\s+\=\s+(\S+)/)
    {
        $controlArgs{NRUNS} = $1;
    }
    if (/OUTPUT_SUFFIX\s+\=\s+(\S+)/)
    {
        $controlArgs{OUTPUT_SUFFIX} = $1;
    }
    if (/RESAMPLE_LOCI\s+\=\s+(\S+)/)
    {
        $controlArgs{RESAMPLE_LOCI} = $1;
    }
    if (/NPROCS\s+\=\s+(\S+)/)
    {
        $controlArgs{NPROCS} = $1;
    }
    if (/STARTING_TREE\s+\=\s+(\S+)/)
    {
        $controlArgs{STARTING_TREE} = $1;
    }
    if (/MAPPING_FILE\s+\=\s+(\S+)/)
    {
        $controlArgs{MAPPING_FILE} = $1;
    }

}
close FH1;

if ($passedArgs{runmode} == 0 || $passedArgs{runmode} == 1)
{
my @loci = ();
my %bootstraps = ();
my @boottreeList = glob("$controlArgs{BOOTSTRAP_DIR}/*.$controlArgs{BOOTSTRAP_SUFFIX}");
my $maxboot = 0;
foreach my $bstf (@boottreeList)
{
	if ($bstf =~ m/$controlArgs{BOOTSTRAP_DIR}\/(\S+)\.$controlArgs{BOOTSTRAP_SUFFIX}/)
	{
		my $prefix = $1;
		push @loci, $prefix;
		my $bootcount = 0;
		open FH1,'<',"$bstf";
		while(<FH1>)
		{
			if (/(\S+;)/)
			{
				my $treeString = $1;
				push @{$bootstraps{$prefix}}, $treeString;
				$bootcount++;
			}
		}
		close FH1;
		if ($maxboot == 0 && $bootcount > 0)
		{
			$maxboot = $bootcount;
		}
		elsif ($maxboot == $bootcount)
		{
			#sanity check
		}
		elsif ($bootcount < $maxboot)
		{
			die ("\n\n/*--------Warning--------*/\nThere are less trees in $bstf than expected.\nCheck that bootstrap analysis finished or that the file was formatted correctly if multiple files were combined.\nThis script does not want you to cheat ;D\n/*-----------------------*/\n\n");
		}
		elsif ($maxboot == 0 && $bootcount == 0)
		{
			die ("\n\n/*--------Warning--------*/\nNo bootstrap trees found in $bstf than expected.\nCheck that bootstrap analysis ran correctly or that the file was formatted correctly if multiple files were combined.\n/*-----------------------*/\n\n");
		}
	}
}

for my $i (1..$controlArgs{NREPS})
{
	open OUT1,'>',"$controlArgs{SNAQ_OUTPUT}/$i.trees";
	for my $j (0..(scalar(@loci)-1))
	{
		if ($controlArgs{RESAMPLE_LOCI} == 0)
		{
			my $rt = int(rand(scalar(@{$bootstraps{$loci[$j]}})));
			print OUT1 "$bootstraps{$loci[$j]}[$rt]\n";
		}
		elsif ($controlArgs{RESAMPLE_LOCI} == 1)
		{
			my $rl = int(rand(scalar(@loci)));
			my $rt = int(rand(scalar(@{$bootstraps{$loci[$rl]}})));
			print OUT1 "$bootstraps{$loci[$rl]}[$rt]\n";
		}
	}
	close OUT1;
}
undef @loci;
undef %bootstraps;
undef @boottreeList;

my $nalleles = 0;
my $hasheader = 0;
my %alleleCounts = ();
open FH1,'<',"$controlArgs{MAPPING_FILE}";
while (<FH1>)
{	
	my $line = $_;
	chomp $line;
	if ($line =~ m/allele,species/)
	{
		$hasheader = 1
	}
	elsif ($line =~ m/(\S+),(\S+)/)
	{
		my $allele = $1;
		my $species = $2;
		$nalleles++;
		if (! exists $alleleCounts{$species})
		{
			$alleleCounts{$species} = 1;
		}
		elsif (exists $alleleCounts{$species})
		{
			$alleleCounts{$species} = $alleleCounts{$species} + 1;
		}
	}
}
close FH1;
if ($hasheader == 0)
{
	die ("\n\n/*--------Warning--------*/\nDetected $nalleles alleles/individuals/haplotypes total, but the header is missing!\nThe mapping file should look something like this:\n\nallele,species\nA-1,A\nA-2,A\nB-1,B\nB-2,B\nC-1,C\nC-2,C\nD-1,D\nD-2,D\nE-1,E\nE-2,E\n\nConsult the PhyloNetworks wiki for more details\n/*-----------------------*/\n\n");
}
elsif ($hasheader == 1)
{
	print "\nDetected the following species and their respective number of alleles:\n";
	foreach my $species (keys %alleleCounts)
	{
		print "$species\t$alleleCounts{$species}\n";
	}
	print "\n\nSNaQ jobs will now be distributed\n\n";
}

for my $i (1..$controlArgs{NREPS})
{
	my $rseed = int(rand(10000000000));
	open OUT1,'>',"$controlArgs{SNAQ_OUTPUT}/$i.jl";
	print OUT1 "using PhyloNetworks\nusing CSV\nusing Distributed\nusing DataFrames\n";

	if ($controlArgs{NPROCS} > 1)
	{
		my $addprocs = $controlArgs{NPROCS} - 1;
		print OUT1 "addprocs($addprocs)\n\@everywhere using PhyloNetworks\n";
	}
	
	if ($passedArgs{runmode} == 0)
	{
		print OUT1 "
T_sp = readTopology(\"$controlArgs{STARTING_TREE}\")
genetrees = readMultiTopology(\"$i.trees\")
tm = DataFrame(CSV.File(\"$controlArgs{MAPPING_FILE}\"))
taxonmap = Dict(tm[i,:allele] => tm[i,:species] for i in 1:$nalleles)
df_sp = writeTableCF(countquartetsintrees(genetrees, taxonmap)...)
CSV.write(\"$i.cftable.csv\", df_sp)
d_sp = readTableCF(\"$i.cftable.csv\")
net = snaq!(T_sp, d_sp, hmax=$controlArgs{HMAX}, runs=$controlArgs{NRUNS}, filename=\"$i.$controlArgs{OUTPUT_SUFFIX}\", seed=$rseed);
";
		close OUT1;
	}
	elsif ($passedArgs{runmode} == 1)
	{
		print OUT1"
T_sp = readTopology(\"$controlArgs{STARTING_TREE}\")
genetrees = readMultiTopology(\"$i.trees\")
tm = DataFrame(CSV.File(\"$controlArgs{MAPPING_FILE}\"))
taxonmap = Dict(tm[i,:allele] => tm[i,:species] for i in 1:$nalleles)
df_ind = writeTableCF(countquartetsintrees(genetrees)...)
CSV.write(\"$i.cfalleletable.csv\", df_ind)
df_sp = mapAllelesCFtable(taxonmap, \"$i.cfalleletable.csv\");
d_sp = readTableCF!(df_sp);
df_sp = writeTableCF(d_sp)
CSV.write(\"$i.cfsptable.csv\", df_sp)
net = snaq!(T_sp, d_sp, hmax=$controlArgs{HMAX}, runs=$controlArgs{NRUNS}, filename=\"$i.$controlArgs{OUTPUT_SUFFIX}\", seed=$rseed);
";
		close OUT1;
	}
	open OUT1,'>',"$controlArgs{SNAQ_OUTPUT}/$i.sh";
	open FH1,'<',"template.sh";
	while (<FH1>)
	{
		my $line = $_;
		chomp $line;
		print OUT1 "$line\n";
	}
	close FH1;
	print OUT1 "cd $controlArgs{SNAQ_OUTPUT}\n";
	print OUT1 "$controlArgs{JULIA_BINARY} $i.jl\n";
	close OUT1;
	system "$controlArgs{SCHEDULER} $controlArgs{SNAQ_OUTPUT}/$i.sh";
}
}

if ($passedArgs{runmode} == 2)
{
	open OUT1,'>',"bootstrapNetworks.txt";
	for my $i (1..$controlArgs{NREPS})
	{
		open FH1,'<',"$controlArgs{SNAQ_OUTPUT}/$i.$controlArgs{OUTPUT_SUFFIX}.out";
		while (<FH1>)
		{
			my $line = $_;
			chomp $line;
			if ($line =~ m/(\S+;)\s+\-Ploglik\s+\=\s+\S+/)
			{
				my $bestNetwork = $1;
				print OUT1 "$bestNetwork\n";
			}
		}
		close FH1;
	}
	close OUT1;
}
exit;
