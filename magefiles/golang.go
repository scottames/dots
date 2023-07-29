package main

import (
	"github.com/magefile/mage/mg"
	"github.com/scottames/cmder"
)

// Go - all things go.
type Go mg.Namespace

// Test - go tests.
func (g Go) Test() error {
	mg.Deps(g.Tidy)

	return cmder.New("go", "test", "./...").Run()
}

// Tidy - go mod tidy.
func (Go) Tidy() error {
	return cmder.New("go", "mod", "tidy").Run()
}
