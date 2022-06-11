# bootSNaQ-MA
Wrapper script for bootstrapping with SNaQ when there are multiple alleles per species

Generating bootstrap replicates for SNaQ in the presence of multiple alleles is not straightforward from within the package, but it is easy enough to split up each bootstrap search as a seperate SNaQ job. This saves time when many processors are available. The baic options for a SNaQ search are configured through the control file (parameter.ctl) and other changes to deafult settings would require direct editing of the BootSNaQ-MA.pl scrip on line 254 or 271 depending which analysis is used.

Aside from configuring the control file and your template.sh file, there are three "runmodes" taken as command line arguments:
* runmode = 0

    analyze [between-species quartets](http://crsl4.github.io/PhyloNetworks.jl/latest/man/multiplealleles/#between-species-4-taxon-sets) only

* runmode = 1

    analyze [between- and witin-species quartets](http://crsl4.github.io/PhyloNetworks.jl/latest/man/multiplealleles/#within-species-4-taxon-sets)

* runmode = 2

    collect the best network from each analysis of a collection of bootstrap trees into a file called `bootstrapNetworks.txt`. You would use this file for getting the bootstrap proportions on a network in PhyloNetworks/PhyloPlots.


