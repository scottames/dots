package main

import (
	"github.com/magefile/mage/mg"
	"github.com/scottames/cmder"
)

// Go - all things go.
type Go mg.Namespace

// About - print about.
func (g Go) Test() error {
	mg.Deps(g.Tidy)

	return cmder.New("go", "test", "./...").Run()
}

func (Go) Tidy() error {
	return cmder.New("go", "mod", "tidy").Run()
}
