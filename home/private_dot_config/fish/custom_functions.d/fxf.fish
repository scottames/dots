#!/bin/env fish

function fxf --description "Search functions + execute selsected"
  set _cmd ( functions | fzf --preview 'fish -c "functions {}"' )
  eval $_cmd
end
