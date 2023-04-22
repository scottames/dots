#!/bin/env fish

function tf_rm --description "Purge .terraform cache"
  find . \( \
    -iname ".terraform*" \
    ! -iname ".terraform-version" \
    ! -iname ".terraform-docs*"  \
  \) -print0 \
  | xargs -0 rm -r
end
