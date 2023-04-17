package helpers

import (
	"path"
	"strings"

	"github.com/scottames/cmder"
)

const (
	git = "git"
)

// GitClone clones a repository (url) optionally in a given destination folder (dest)
// ex:
//
//	GitClone("https://github.com/example/example.git","/tmp") // clone in /tmp
//	GitClone("https://github.com/example/example.git",nil")   // current directory
func GitClone(url string, dest *string) error {
	cmd := cmder.New(git, "clone", url)
	if dest != nil {
		cmd.Dir(*dest)
	}

	return cmd.Run()
}

// GitTag returns the git tag for the current branch or "" if none and a possible error.
func GitTag() (string, error) {
	o, err := cmder.New(git, "describe", "--tags").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(o)), nil
}

// GitHash returns the git hash for the current repo or "" if none and a possible error.
func GitHash() (string, error) {
	o, err := cmder.New(git, "rev-parse", "--short", "HEAD").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(o)), nil
}

// GitBranch returns the current git branch and a possible error.
func GitBranch() (string, error) {
	o, err := cmder.New(git, "rev-parse", "--abbrev-ref", "HEAD").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(o)), nil
}

// GitProj - Git project info.
type GitProj struct {
	Org  string // git organization, assumed from project parent directory
	Name string // git project name
	Root string // git project root (directory)
}

// GitProj - returns git project info.
func NewGitProj() (*GitProj, error) {
	gp := GitProj{}

	r, err := gp.root()
	if err != nil {
		return nil, err
	}
	gp.Root = r
	gp.Name = path.Base(gp.Root)
	gp.Org = path.Base(path.Dir(gp.Root))

	return &gp, nil
}

// Root returns the git project root and a possible error.
func (GitProj) root() (string, error) {
	o, err := cmder.New(git, "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(o)), nil
}
