#!/bin/sh
outdir=/tmp/bundle/$1; shift
test -e $outdir || mkdir -p $outdir
(cd $outdir; apt-get -sy install $@ | \
	awk '/^Inst /{print $2}' | \
	xargs apt-get download)
