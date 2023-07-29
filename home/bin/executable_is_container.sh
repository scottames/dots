#!/bin/env bash

if [[ ! -f /run/.containerenv ]]; then
  echo false
  exit 1
fi

echo true
