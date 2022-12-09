# copyright 2017-2023 Regents of the University of California and the Broad Institute. All rights reserved.
FROM ubuntu:20.04

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC

RUN \
  sed -Ei 's/^# (deb.*xenial-backports.*)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \ 
  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y software-properties-common && \
  apt-get install -y autoconf automake byobu bzip2 curl gfortran git htop lzma man sudo unzip vim wget && \
  apt-get install -y libbz2-dev libcurl4-openssl-dev libgsl0-dev liblzma-dev libncurses5-dev libpcre3-dev \
  libreadline6-dev libssl-dev python-dev python3-pip zlib1g-dev && \
  rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y g++ make

# get NBCI Toolkit
WORKDIR /tmp
RUN wget https://ftp-trace.ncbi.nlm.nih.gov/sra/ngs/2.9.0/ngs-sdk.2.9.0-linux.tar.gz && \
    tar xzvf ngs-sdk.2.9.0-linux.tar.gz

RUN apt-get install -y libarchive-extract-perl

# Install  StarAligner
WORKDIR /star_install
RUN wget https://github.com/alexdobin/STAR/archive/refs/tags/2.7.10b.tar.gz && \
    tar -xzf 2.7.10b.tar.gz && \
    cd STAR-2.7.10b 
    
ENV PATH="/star_install/STAR-2.7.10b/bin/Linux_x86_64:${PATH}"


RUN apt-get update && \
   apt-get install zip --yes
RUN cpan -f Archive::Zip

# CMD ["/usr/local/bin/runS3OnBatch.sh" ]

