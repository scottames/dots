package main

import (
	"fmt"
	"strings"
	"time"

	"github.com/fatih/color"
	"github.com/magefile/mage/mg"
	"github.com/scottames/cmder"

	"github.com/scottames/dots/pkg/helpers"
)

const (
	fs         = "/"
	dockerfile = "Dockerfile"
)

func dockerTagBase(org, proj, target string) string {
	return org + fs + proj + fs + target
}

// Docker - Docker actions.
type Docker mg.Namespace

// Build - build docker image - specify valid target from assets/docket/*.
func (d Docker) Build(target string) error {
	gp, err := helpers.NewGitProj()
	if gp == nil {
		return fmt.Errorf("unable to get git project info - nil response")
	}
	if err != nil {
		return fmt.Errorf("getting git project info: %w", err)
	}

	td, err := d.targetDir(target, gp)
	if err != nil {
		return err
	}
	if td == nil {
		return fmt.Errorf("unable to determine docker target directory - empty result")
	}

	df := *td + fs + dockerfile
	now := time.Now().Format(time.RFC3339)
	dockerTag := dockerTagBase(gp.Org, gp.Name, target)
	dockerTagLatest := dockerTag + ":latest"

	gitTag, err := helpers.GitTag()
	if err != nil {
		return err
	}

	vcsRef, err := helpers.GitHash()
	if err != nil {
		return err
	}

	pBlack := color.New(color.FgBlack)
	pInfo := color.New(color.FgMagenta)
	pBlack.Printf("# -------------------------------------------------------------------\n")
	pBlack.Printf("# ")
	pInfo.Printf("BUILD DATE: ")
	fmt.Printf("%s\n", now)

	pBlack.Printf("# ")
	pInfo.Printf("VERSION:    ")
	fmt.Printf("%s\n", gitTag)

	pBlack.Printf("# ")
	pInfo.Printf("VCS_REF:    ")
	fmt.Printf("%s\n", vcsRef)

	pBlack.Printf("# ")
	pInfo.Printf("DOCKER_TAG: ")
	fmt.Printf("%s\n", dockerTagLatest)
	pBlack.Printf("# -------------------------------------------------------------------\n")

	return cmder.New("docker", "build",
		"-f", df,
		"--build-arg", fmt.Sprintf("BUILD_DATE=%s", now),
		"--build-arg", fmt.Sprintf("VERSION=%s", gitTag),
		"--build-arg", fmt.Sprintf("VCS_REF=%s", vcsRef),
		"-t", dockerTagLatest,
		".").Run()
}

func (Docker) isBuilt(image string) (*bool, error) {
	images, err := cmder.New("docker", "images", "-q", image).Output()
	if err != nil {
		return nil, err
	}

	ib := len(images) > 0

	return &ib, nil
}

// run - run docker against the given target with the optional cmd.
func (d Docker) run(target string, args []string, cmd *string) error {
	gp, err := helpers.NewGitProj()
	if gp == nil {
		return fmt.Errorf("unable to get git project info - nil response")
	}
	if err != nil {
		return fmt.Errorf("getting git project info: %w", err)
	}

	dockerTag := dockerTagBase(gp.Org, gp.Name, target)
	dockerTagLatest := dockerTag + ":latest"

	ib, ibErr := d.isBuilt(dockerTagLatest)
	if ibErr != nil {
		return ibErr
	}
	if ib == nil {
		return fmt.Errorf("unable to find docker image for '%s' - nil result", target)
	}

	if !*ib {
		color.Magenta("\n=> image not found for '%s', attempting to build it\n\n", target)
		buildErr := d.Build(target)
		if buildErr != nil {
			return buildErr
		}
	}

	dr := cmder.New("docker", "run", "--rm")
	if args != nil {
		dr.Args(args...)
	}
	dr.Args("-it", dockerTagLatest, "/bin/bash")
	if cmd != nil {
		dr.Args("-c", *cmd)
	}

	return dr.Run()
}

// Run - the given docker container (1).
func (d Docker) Run(target string) error {
	return d.run(target, nil, nil)
}

// Runcmd - the given docker container (1) with the given command (2).
func (d Docker) Runcmd(target, cmd string) error {
	return d.run(target, nil, &cmd)
}

func (Docker) targetDir(target string, gp *helpers.GitProj) (*string, error) {
	if gp == nil {
		return nil, fmt.Errorf("found empty git project info when trying to determine docker target dir")
	}

	dockerDir := gp.Root + "/assets/docker/"
	targetDir := dockerDir + target
	validDockerTargets, err := helpers.ListDirs(dockerDir)
	if err != nil {
		return nil, fmt.Errorf("unable to determine valid docker targets in project: %w", err)
	}

	isValidTarget, err := helpers.IsDir(targetDir)
	if err != nil {
		return nil, err
	}
	if !isValidTarget {
		return nil, fmt.Errorf("invalid target: %s\n  valid options: %s", target, strings.Join(validDockerTargets, ","))
	}

	return &targetDir, nil
}
