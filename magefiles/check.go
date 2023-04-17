package main

import (
	"github.com/magefile/mage/mg"
	"github.com/scottames/cmder"
)

const (
	check = "check"
	trunk = "trunk"
)

// Check - run all checks (trunk).
func Check() {
	mg.Deps(
		Trunk.Check,
	)
}

// Trunk - trunk.io.
type Trunk mg.Namespace

// Check - trunk check.
func (Trunk) Check() error {
	return cmder.New(trunk, check).Run()
}

// Checkall - trunk check.
func (Trunk) Checkall() error {
	return cmder.New(trunk, check, "-a").Run()
}
