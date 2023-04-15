package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/magefile/mage/mg"
	"github.com/scottames/cmder"

	"github.com/scottames/dots/pkg/helpers"
)

const (
	sudo     = "sudo"
	paru     = "paru"
	paruGit  = "https://aur.archlinux.org/paru.git"
	paruHome = "https://github.com/Morganamilo/paru"
)

type Paru mg.Namespace

// About - print about.
func (Paru) About() {
	fmt.Printf("\n%s\n", paruHome)
}

// Install - install paru from AUR.
func (Paru) Install() error {
	var err error
	tmpDir, err := os.MkdirTemp("", "paru")
	if err != nil {
		return fmt.Errorf("error creating temp dir: %w", err)
	}
	err = helpers.GitClone(paruGit, &tmpDir)
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmpDir)

	cloneDir := tmpDir + "/paru"
	err = cmder.New("makepkg", "-s").Dir(cloneDir).Run()
	if err != nil {
		return err
	}

	pkg, err := filepath.Glob(tmpDir + "/paru*.pkg.tar.zst")
	if err != nil {
		return err
	}
	if len(pkg) == 0 {
		return fmt.Errorf("unable to find %s package to install", paru)
	}

	fmt.Printf("\nInstalling %s...\n\n", paru)

	return cmder.New(sudo, "pacman", "--noconfirm", "-U", pkg[0]).Run()
}
