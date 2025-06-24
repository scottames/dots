package main

import (
	"context"
	"dagger/dots/internal/dagger"
	"fmt"
)

type Dots struct {
	Source *dagger.Directory
}

func New(
	ctx context.Context,
	// root of dots repository
	// +defaultPath="/"
	source *dagger.Directory,
) *Dots {
	return &Dots{
		Source: source,
	}
}

// Run init inside a container.
func (m *Dots) Init(
	ctx context.Context,
	// container to pull from
	//   see also: https://github.com/scottames/containers
	// +optional
	// +default="ghcr.io/scottames/fedora-toolbox:latest"
	from string,
	// path inside container to init to mount the dotfiles
	// +optional
	// +default="/root/src/github.com/scottames/dots/main"
	dotsMountPath string,
) *dagger.Container {
	ctr := dag.Container().
		WithMountedDirectory(
			dotsMountPath,
			m.Source,
		)

	return ctr.
		From(from).
		WithExec([]string{
			fmt.Sprintf("%s/scripts/init.sh", dotsMountPath),
			"--no-tty", "--promptDefaults",
		})
}
