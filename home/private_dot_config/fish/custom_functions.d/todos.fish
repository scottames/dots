#!/bin/env fish

function todos --description "List TODOs in project"
  if [ $HAS_RG ]
    rg "TODO|FIXME"
  else
    grep -r -e "TODO" -e "FIXME" .
  end
end
