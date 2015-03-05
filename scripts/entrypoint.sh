#!/bin/bash

ALLCMDS=('build' 'run')
for cmd in "${ALLCMDS[@]}"; do
  if [ "$1" == "$cmd" ]; then
    source /scripts/functions
    run_scripts $cmd
    exit 0
  fi
done

exec "$@"
