package main

import (
	"github.com/magefile/mage/mg"
)

// Aliases - target aliases.
var Aliases = map[string]interface{}{}

// All - wraps all commands into one.
type All mg.Namespace

// Backup - backup all.
func (All) Backup() {
	mg.Deps(
		Gs.Backupall,
	)
}

// Restore - restore all.
func (All) Restore() {
	mg.Deps(
		Gs.Restore,
	)
}
