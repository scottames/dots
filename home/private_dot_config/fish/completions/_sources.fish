#!/bin/env fish

set -l completion_bins \
    chezmoi \
    dagger \
    flux \
    helm \
    kubectl \
    kustomize

for bin in $completion_bins
    type -q $bin
    and $bin completion fish | source
end
