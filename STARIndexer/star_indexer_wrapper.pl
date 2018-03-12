use Getopt::Long;
use Archive::Zip;
use File::Path qw(make_path remove_tree);

#$star = 'STAR-2.5.2b/bin/Linux_x86_64_static/STAR';
$star = '/star_install/STAR-2.5.3a/bin/Linux_x86_64_static/STAR';
$Nthreads = 4;

GetOptions(\%options,
  "fastafilelist=s", # is always file 'fasta.file.list.txt'
  "GTFfile=s", # optional in interface
  "tabfile=s", # optional in interface
  "indexdir=s",
  "overhang=i",
  "indexstringlength=i",
  "binsize=i",
  "RAM=i" # in gigabyte
);

# make a directory to temporarily store the index,
#   we will later put the index in a zip file
$indexdir = $options{'indexdir'};
make_path $indexdir;

# write the STAR command line and execute it
$cmd = "$star --runMode genomeGenerate --runThreadN $Nthreads";
open FASTAFILELIST, $options{fastafilelist};
  @fastafiles = <FASTAFILELIST>;
close FASTAFILELIST;
$cmd .= ' --genomeFastaFiles';
foreach $fastafile (@fastafiles) {
  chop $fastafile; # remove end-of-line
  $cmd .= " $fastafile";
}
if (exists $options{'GTFfile'}) {
  $cmd .= " --sjdbGTFfile $options{'GTFfile'}";
}
if (exists $options{'tabfile'}) {
  $cmd .= " --sjdbFileChrStartEnd $options{'tabfile'}";
}
$cmd .= " --genomeDir $options{'indexdir'}";
if (exists $options{'GTFfile'} or exists $options{'tabfile'}) {
  $cmd .= " --sjdbOverhang $options{'overhang'}";
}
$cmd .= " --genomeSAindexNbases $options{'indexstringlength'}";
$cmd .= " --genomeChrBinNbits $options{'binsize'}";
$RAM = $options{'RAM'} * 1000000000;
$cmd .= " --limitGenomeGenerateRAM $RAM";
print "$cmd\n"; # for debugging
system($cmd);

# put the index into a zip file and remove it
$zip = Archive::Zip->new();
$zip->addDirectory($indexdir);
opendir INDEXDIR, $indexdir;
while ($file = readdir INDEXDIR) {
  if (-f "$indexdir/$file") { # not use the directories '.' and '..'
    $zip->addFile("$indexdir/$file");
  }
}
closedir INDEXDIR;
$zip->writeToFileNamed("$indexdir.zip");
remove_tree($indexdir);
