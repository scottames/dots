#!/bin/env fish

function print_path --description "Pretty print PATH"
    string replace ":" "\n" $PATH | awk "{
      sub(\"$HOME\",  \"$(set_color green  )$HOME$(set_color normal)\"); \
      sub(\"/usr\",   \"$(set_color green  )/usr$(set_color normal)\"); \
      sub(\"/bin\",   \"$(set_color blue   )/bin$(set_color normal)\"); \
      sub(\"/opt\",   \"$(set_color cyan   )/opt$(set_color normal)\"); \
      sub(\"/sbin\",  \"$(set_color magenta)/sbin$(set_color normal)\"); \
      sub(\"/local\", \"$(set_color yellow )/local$(set_color normal)\"); \
      sub(\"/.rvm\",  \"$(set_color red    )/.rvm$(set_color normal)\"); \
    print }"
end
