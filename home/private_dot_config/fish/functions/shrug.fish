#!/bin/env fish

function shrug --description "Copies $SHRUG to the clipboard"
  printf $SHRUG | setclip && printf_info "¯\\_(ツ)_/¯ copied to your clipboard\n"
end
