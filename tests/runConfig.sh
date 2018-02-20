
INPUT_FILE_DIRECTORIES=$PWD/data
TASKLIB=$PWD/src/
COMMAND_LINE="perl $TASKLIB/star_aligner_wrapper.pl --patchesdir / --index $INPUT_FILE_DIRECTORIES/reads12index.zip --reads1 $INPUT_FILE_DIRECTORIES/reads.pair.1.list.txt --reads2 $INPUT_FILE_DIRECTORIES/reads.pair.2.list.txt --alignendtoend no --maxNmismatch 10 --maxFmismatch 0.3 --minoverhangannot 3 --minoverhangnotannot 5 --minintronlength 21 --maxintronlength 500000 --matesmaxgap 500000 --multimapmismatchrange 0 --maxmultimap 10 --canonicaloverhang 12 --noncanonicaloverhang 30 --maponlyreportedjunctions no --twopass no --detectchimeric no --outputunmapped no --quantify no --wiggle None --wigglesignal all --format SAM --HIflag OneBestScore --outputprefix STAR"

CONTAINER_OVERRIDE_MEMORY=3100
JOB_DEFINITION_NAME="STAR"
JOB_ID=STAR_ALGN_$1
JOB_QUEUE=TedTest
S3_ROOT=s3://moduleiotest
WORKING_DIR=$PWD/job_52345

DOCKER_CONTAINER=genepattern/docker-staraligner


