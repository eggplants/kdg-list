#!/usr/bin/env bash

if ! [[ -f '漢字でGO!/www/data/Map003.json' ]]
then
  exit 1
fi

grep -oE '207,207,0,4,"\\"[^"]+' '漢字でGO!/www/data/Map003.json' |
  tr -d '"' |
  awk -F '\\' '$0=$2'
