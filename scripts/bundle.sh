#!/bin/sh
outdir=/bundle/$1; shift
mkdir -p $outdir
(cd $outdir; apt-get -sy install $@ | \
	awk '/^Inst /{print $2}' | \
	xargs apt-get download)
ls -al $outdir | md5sum > /bundle/${1}.md5sum
