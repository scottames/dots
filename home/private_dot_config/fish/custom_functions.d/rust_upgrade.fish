#!/bin/env fish

function rust_upgrade --description "rust: upgrade rust + cargos"
    rustup update && cargo_upgrade
end
