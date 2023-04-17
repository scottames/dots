package main

import (
	"fmt"

	"github.com/magefile/mage/mg"

	"github.com/scottames/dots/pkg/helpers"
)

// Test - run all tests (docker + chezmoi init).
func Test() {
	mg.Deps(
		dockerRunTest,
		Go.Test,
	)
}

// dockerRunTest - runs chezmoi init inside archlinux docker container.
func dockerRunTest() error {
	gp, err := helpers.NewGitProj()
	if gp == nil {
		return fmt.Errorf("unable to get git project info - nil response")
	}
	if err != nil {
		return fmt.Errorf("getting git project info: %w", err)
	}

	chezmoiSource := "/home/container/src/" + gp.Org + fs + gp.Name
	vol := gp.Root + ":" + chezmoiSource
	args := []string{"-v", vol}
	cmd := chezmoiSource + "/scripts/init.sh"
	d := Docker{}
	target := "archlinux"
	return d.run(
		target,
		args,
		&cmd,
	)
}
