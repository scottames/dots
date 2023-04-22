#!/bin/env fish

function fx --description "Search functions + execute selsected"
  set _cmd ( functions | fzf --preview 'fish -c "functions {}"' )
  eval $_cmd
end
