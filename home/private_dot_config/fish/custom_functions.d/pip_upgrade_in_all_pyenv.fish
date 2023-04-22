#!/bin/env fish

function pip_upgrade_in_all_pyenv --description "upgrate pip in all pyenv virtualenvs"
  for VERSION in (pyenv versions --bare)
    pyenv shell $VERSION
    pip install --upgrade pip
  end
end
