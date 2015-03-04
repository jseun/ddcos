#!/bin/bash

export SHDIR=$(dirname $0)
source ${SHDIR}/functions
run_scripts ${SHDIR}/${1-init}
exec /bin/bash
