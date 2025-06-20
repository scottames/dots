package main

import (
	"context"
	"dagger/dots/internal/dagger"
)

type Dots struct {
	Source *dagger.Directory
}

func (m *Dots) New(
	ctx context.Context,
	// dots source directory
	// +defaultPath="."
	source *dagger.Directory,
) *Dots {
	return &Dots{
		Source: source,
	}
}

// Run init inside a container.
func (m *Dots) Init(
	ctx context.Context,
	// dots source directory
	// +defaultPath="."
	source *dagger.Directory,
	// branch to init against
	// +optional
	// +default="main"
	branch string,
) *dagger.Container {
	return dag.Container().
		WithMountedDirectory(
			"/home/container/src/github.com/scottames/dots/main",
			source,
		).
		From("ghcr.io/scottames/fedora-toolbox:latest").
		Terminal().
		WithExec([]string{
			"/home/container/src/github.com/scottames/dots/main/scripts/init.sh",
			"--no-tty", "--branch", branch,
			"--promptDefaults",
		})
}
