package main

import (
	"github.com/magefile/mage/mg"
)

// Aliases - target aliases.
var Aliases = map[string]interface{}{
	"dconf:restore": Dconf.Loadall,
}

// All - wraps all commands into one.
type All mg.Namespace

// Backup - backup all.
func (All) Backup() {
	mg.Deps(
		Dconf.Backupall,
	)
}

// Restore - restore all.
func (All) Restore() {
	mg.Deps(
		Dconf.Loadall,
	)
}
