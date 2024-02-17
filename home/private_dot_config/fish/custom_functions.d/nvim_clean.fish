#!/bin/env fish

function nvim_clean
    set -l _dirs \
        ~/.local/share/nvim \
        ~/.local/state/nvim \
        ~/.cache/nvim \
        ~/.local/share/nvim/site/pack/packer/start/packer.nvim \
        ~/.local/share/nvim/lazy/lazy.nvim \
        ~/.local/share/nvim/lazy/nvim-treesitter \
        ~/.local/share/nvim/mason

    for d in $_dirs
        echo $d
        rm -rf $d
    end
end
