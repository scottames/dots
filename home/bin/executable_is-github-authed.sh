#!/usr/bin/env bash

ssh -T git@github.com >/dev/null 2>&1
exit_status=$?

if [ "${exit_status}" -ne 1 ] && [ "${exit_status}" -ne 0 ]; then
  printf "false"
  exit
fi

printf "true"
