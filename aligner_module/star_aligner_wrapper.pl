use Getopt::Long;
use Archive::Extract; # needed for custom index
use File::Path qw(make_path remove_tree); # needed for custom index

#$star = 'STAR-2.5.2b/bin/Linux_x86_64_static/STAR';

$star = '/star_install/STAR-2.5.3a/bin/Linux_x86_64/STAR';

$Nthreads = 4;

GetOptions(\%options,
  "index=s", # an FTP object
  "reads1=s", # if reads2 not precised we assume this is the only list of reads
  "reads2=s", # optional in interface
  "mapN=i", # optional in interface, align only that many first sequences
  "alignendtoend=s", # yes or no (is default)
  "maxNmismatch=i",
  "maxFmismatch=f",
  "minoverhangannot=i",
  "minoverhangnotannot=i",
  "minintronlength=i",
  "maxintronlength=i",
  "matesmaxgaps=i",
  "multimapmismatchrange=i",
  "maxmultimap=i",
  "canonicaloverhang=i",
  "noncanonicaloverhang=i",
  "maponlyreportedjunctions=s", # yes or no (is default)
  "twopass=s", # yes or no (is default)
  "detectchimeric=s", # yes or no (is default)
  "outputunmapped=s", # yes or no (is default)
  "quantify=s", # yes or no (is default)
  "wiggle=s", # None, bedGraph or wiggle
  "wigglesignal=s", # (all), read1_5p or read2
  "format=s", # SAM, BAM Unsorted or BAM SortedByCoordinate
  "HIflag=s", # AllBestScore or OneBestScore
  "outputprefix=s"
);

# start writing command line
$cmd = "$star --runMode alignReads --genomeLoad LoadAndRemove --runThreadN $Nthreads";
 
# add index to command line
# a prebuilt index is in a directory (pointed to by the FTP object)
#   and has the same name as this directory
# a custom index must be in an archive file and will be extracted
#   and after the STAR run is complete the index is deleted
if (-d $options{index}) { # is prebuilt index from VIB FTP server
  $cmd .= " --genomeDir $options{index}";
} else { # user provided ZIP file with index
  $zipfile = $options{index}; 
  $indexarchive = Archive::Extract->new(archive => $zipfile);
  if (not ($indexarchive->is_tgz or $indexarchive->is_zip or $indexarchive->is_tbz)) { die "\nCustom index should be in archive with extension .zip .tar.gz .tgz .tar.bz2 .tbz\n" }
  $indexarchive->extract or die "\nCould not extract $zipfile. Are you sure this is a valid archive with a STAR index ?\n";
  @filesfromzip = @{$indexarchive->files};
  $ziptest1 = 1; $ziptest2 = 1;
  foreach $filefromzip (@filesfromzip) {
    if ($filefromzip =~ /^(.+)\/SA$/) { $ziptest1 = 0 ; $indexdir = $1 }
    if ($filefromzip =~ /^.+\/SAindex$/) { $ziptest2 = 0 }
  }
  if ($ziptest1 or $ziptest2) {
    die "\n$zipfile\ndoes not look like a valid STAR index, it should contain a directory/folder with inside files 'SA' and 'SAindex'\n";
  }
  $cmd .= " --genomeDir $indexdir";
}

# add reads to command line, note that you can have multiple files
open READSLIST, $options{reads1};
  @reads1 = <READSLIST>;
close READSLIST;
foreach $filename (@reads1) {
  chomp $filename; # remove end-of-line
  $reads1 .= "$filename,";
}
chop $reads1; # remove last ','
$cmd .= " --readFilesIn $reads1";
if (exists $options{reads2}) {
  open READSLIST, $options{reads2};
    @reads2 = <READSLIST>;
  close READSLIST;
  if ($#reads1 != $#reads2) {
    die "\nThe reads must be in the same number of files!\n";
  }
  foreach $filename (@reads2) {
    chomp $filename; # remove end-of-line
    $reads2 .= "$filename,";
  }
  chop $reads2; # remove last ','
  $cmd .= " $reads2";
}

# complete command line
if (exists $options{mapN}) {
  $cmd .= " --readMapNumber $options{mapN}";
}
if ($options{alignendtoend} eq 'yes') {
  $cmd .= ' --alignEndsType EndToEnd';
}
$cmd .= " --outFilterMismatchNmax $options{maxNmismatch}";
$cmd .= " --outFilterMismatchNoverLmax $options{maxFmismatch}";
$cmd .= " --alignSJDBoverhangMin $options{minoverhangannot}";
$cmd .= " --alignSJoverhangMin $options{minoverhangnotannot}";
$cmd .= " --alignIntronMin $options{minintronlength}";
$cmd .= " --alignIntronMax $options{maxintronlength}";
if (exists $options{reads2}) {
  $cmd .= " --alignMatesGapMax $options{matesmaxgaps}";
}
if ($options{multimapmismatchrange} > 0) {
  # a mismatch/indel adds a penalty of -2 to the score, hence we need
  # a scorerange of at least 2 to report secondary mappings
  $scorerange = $options{multimapmismatchrange} * 2;
  $cmd .= " --outFilterMultimapScoreRange $scorerange"
}
$cmd .= " --outFilterMultimapNmax $options{maxmultimap}";
$cmd .= " --outSJfilterOverhangMin $options{canonicaloverhang} $options{noncanonicaloverhang} $options{noncanonicaloverhang} $options{noncanonicaloverhang}"; 
if ($options{maponlyreportedjunctions} eq 'yes') {
  $cmd .= ' --outFilterType BySJout';
}
if ($options{twopass} eq 'yes') {
  $cmd .= ' --twopassMode Basic';
  $cmd =~ s/LoadAndRemove/NoSharedMemory/;
    # cannot use shared memory because STAR adds splice junction annotations
    # found during first pass on-the-fly to the run's own index in RAM
} 
if ($options{detectchimeric} eq 'yes'){
  $cmd .= ' --chimSegmentMin 1';
}
if ($options{outputunmapped} eq 'yes') {
  $cmd .= ' --outReadsUnmapped Fastx';
}
if ($options{quantify} eq 'yes') {
  $cmd .= '  --quantMode TranscriptomeSAM GeneCounts';
}
$cmd .= " --outWigType $options{wiggle}";
if ($options{wiggle} ne 'None') {
  $options{format} = 'BAM SortedByCoordinate';
  # creating wiggle file needs sorted BAM file 
}
if ($options{wigglesignal} ne 'all') {
  $cmd .= " $options{wigglesignal}";
}
$cmd .= " --outSAMtype $options{format}";
if ($options{format} eq 'BAM SortedByCoordinate') {
  $cmd =~ s/LoadAndRemove/NoSharedMemory/;
  # cannot use shared memory for sorted BAM format
}
$cmd .= " --outSAMprimaryFlag $options{HIflag}";
if (exists $options{outputprefix}) {
  $cmd .= " --outFileNamePrefix $options{outputprefix}.";
  # final '.' as separator is not added by STAR itself
}

# execute STAR and if needed remove temporary data
#print "$cmd\n"; # for debugging
system($cmd);
if (-e $indexdir) {
  remove_tree($indexdir);
}
if ($options{twopass} eq 'yes') {
  remove_tree("$options{outputprefix}._STARgenome");
  remove_tree("$options{outputprefix}._STARpass1");
}
