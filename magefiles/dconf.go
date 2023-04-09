package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/scottames/cmder"

	"github.com/scottames/dots/pkg/helpers"
)

const (
	dconf     string = "dconf"
	backupDir string = "./dconf"
	root             = "/"
)

var dirs = []string{
	"/com/gexperts/Tilix/",                           // https://github.com/gnunn1/tilix/
	"/org/gnome/shell/extensions/paperwm/",           // https://github.com/paperwm/PaperWM
	"/org/gnome/settings-daemon/plugins/media-keys/", // custom key bindings + media keys
	"/org/gnome/desktop/wm/keybindings/",             // keybindings
}

// Dconf - Gnome Dconf settings.
type Dconf mg.Namespace

// Backup - backup named dconf setting.
func (Dconf) Backup(key string) error {
	mg.Deps(Dconf.installed)

	dump, err := cmder.New(dconf, "dump", key).Output()
	if err != nil {
		return err
	}

	var file string
	if key == root {
		file = "all.conf"
	} else {
		file = fileNameFromKey(key)
	}

	if _, statErr := os.Stat(backupDir); os.IsNotExist(statErr) {
		mkDirErr := os.MkdirAll(backupDir, 0700)
		if mkDirErr != nil {
			return fmt.Errorf("error creating backup dir (%s): %w", backupDir, err)
		}
	}

	backupPath := filepath.Join(backupDir, file)
	err = os.WriteFile(backupPath, dump, 0600)
	if err != nil {
		return err
	}

	return nil
}

// Backupall - backup all tracked dconf settings.
func (d Dconf) Backupall() error {
	for _, key := range dirs {
		err := d.Backup(key)
		if err != nil {
			return err
		}
		fmt.Println(key)
	}
	return nil
}

// Dump - dump named (or all, default) dconf setting(s).
func (d Dconf) Dump(s string) error {
	if s == "" || s == "all" {
		s = root
	}
	return d.Backup(s)
}

// Load - load named dconf setting.
func (Dconf) Load(key string) error {
	mg.Deps(Dconf.installed)

	_, err := os.ReadDir(backupDir)
	if err != nil {
		return fmt.Errorf("dconf backup dir '%s' not found", backupDir)
	}

	file := fileNameFromKey(key)
	backup := filepath.Join(backupDir, file)
	data, err := os.ReadFile(backup)
	if err != nil {
		return fmt.Errorf("unable to load '%s' from '%s': %w", key, backup, err)
	}

	return cmder.New(dconf, "load", key).In(data...).Run()
}

// Loadall - load all tracked dconf settings.
func (d Dconf) Loadall() error {
	for _, key := range dirs {
		err := d.Load(key)
		if err != nil {
			return err
		}
		fmt.Println(key)
	}
	return nil
}

func (Dconf) installed() error {
	_, err := helpers.Which(dconf)
	return err
}

func fileNameFromKey(key string) string {
	return fmt.Sprintf("%s.conf",
		strings.Trim(
			strings.ReplaceAll(
				strings.Replace(key, "/", "", 1),
				"/", "-"),
			"-"),
	)
}
