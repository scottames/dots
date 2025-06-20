package main

import (
	"bufio"
	"bytes"
	"fmt"
	"os"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/scottames/cmder"
	"gopkg.in/yaml.v3"

	"github.com/scottames/dots/pkg/helpers"
)

const (
	distroboxHostExec        = "distrobox-host-exec"
	gs                       = "gsettings"
	gsBackupFile      string = "./home/.gsettings.yaml"
	indent                   = 2

	dockerEnv    = "/.dockerenv"
	containerEnv = "/run/.containerenv"
)

func isContainer() bool {
	if _, err := os.Stat(containerEnv); err == nil {
		return true
	} else if _, err = os.Stat(dockerEnv); err == nil {
		return true
	}

	return false
}

// newDistroBoxCmd - returns a string slice with "distrobox-host-exec" prepended to the command
// if the command is being executed in a container and "distrobox-host-exec" is available in path.
func newDistroBoxCmd(cmd string) []string {
	isContainer := isContainer()
	cs := []string{}
	if isContainer {
		_, err := helpers.Which(distroboxHostExec)
		if err == nil {
			cs = append(cs, distroboxHostExec)
		}
	}
	cs = append(cs, cmd)
	return cs
}

// GSettings - maps to a schema: key:value.
type GSettings map[string]GSetting

// GSetting - maps to a key: value for a given schema.
type GSetting map[string]string

// Gs - Gnome Gs settings.
type Gs mg.Namespace

// installed - checks whether the gsettings bin is in the path.
func (Gs) installed() error {
	_, err := helpers.Which(gs)
	return err
}

// Backup - backup a given schema.key
// -> specifying 'all' will backup ALL gsettings found in the backup file.
func (g Gs) Backup(scope string) error {
	mg.Deps(Gs.installed)

	var err error
	gs, err := g.ReadBackup()
	if err != nil {
		return err
	}

	var diff bool
	if scope == "all" {
		gs, diff, err = g.GetDiff(gs)
		if err != nil {
			return err
		}
	} else {
		var schema, key string
		schema, key, err = g.schemaKeySplit(scope)
		if err != nil {
			return err
		}

		diff = true
		gs, err = g.getToGSetting(gs, schema, key)
		if err != nil {
			return err
		}
	}

	if diff {
		return g.WriteBackup(gs)
	}

	return nil
}

// Backupall - backup ALL gsettings found in the backup file.
func (g Gs) Backupall() error {
	return g.Backup("all")
}

// Backupschema - backup all keys for a given schema.
func (g Gs) Backupschema(schema string) error {
	mg.Deps(Gs.installed, Gs.Compileschemas)

	keys, err := g.ListKeys(schema)
	if err != nil {
		return err
	}

	gs, err := g.ReadBackup()
	if err != nil {
		return err
	}

	for _, key := range keys {
		gs, err = g.getToGSetting(gs, schema, key)
		if err != nil {
			return err
		}
	}

	return g.WriteBackup(gs)
}

// Compileschemas - search $HOME/.local/share/gnome-shell for schemas, copy to glib-2.0 schemas, compile.
func (Gs) Compileschemas() error {
	home := os.Getenv("HOME")
	schemasDir := fmt.Sprintf("%s/.local/share/glib-2.0/schemas/", home)

	var err error
	err = cmder.New("mkdir", "-p", schemasDir).Silent().Run()
	if err != nil {
		return err
	}

	lsGs := fmt.Sprintf("%s/.local/share/gnome-shell/", home)
	files, err := helpers.FindFiles(lsGs, "*.gschema.xml")
	if err != nil {
		return err
	}
	for _, file := range files {
		err = cmder.New("cp", file, schemasDir).Silent().Run()
		if err != nil {
			return err
		}
	}

	cmd := newDistroBoxCmd("glib-compile-schemas")
	return cmder.New(cmd...).Args(schemasDir).Silent().Run()
}

// Get - retrieve the value for a schema & key
// returns the value and any possible error.
func (Gs) Get(schema string, key string) (string, error) {
	gsCmd := newDistroBoxCmd(gs)
	val, err := cmder.New(gsCmd...).Args("get", schema, key).Silent().CombinedOutput()
	if err != nil {
		return "", fmt.Errorf(
			"err getting '%s' '%s'\n %s",
			schema,
			key,
			strings.TrimSpace(string(val)),
		)
	}

	return strings.TrimSpace(string(val)), nil
}

// GetDiff - ranges over given gsettings getting the value in the database
// returns the updated gsettings, true if there is a difference, and any possible error.
func (g Gs) GetDiff(gs GSettings) (GSettings, bool, error) {
	diff := false
	for schema, keys := range gs {
		fmt.Printf("[ %s ]\n", schema)
		for key, fv := range keys {
			nv, err := g.Get(schema, key)
			if err != nil {
				return gs, diff, err
			}

			if fv != nv {
				diff = true
				fmt.Printf("key: %s\n  old: %s\n  new: %s\n", key, fv, nv)
				gs[schema][key] = nv
			}
		}
	}

	return gs, diff, nil
}

// getToGSetting - gets the given schema and key
// returning the given GSettings with the value inserted.
func (g Gs) getToGSetting(gs GSettings, schema string, key string) (GSettings, error) {
	val, err := g.Get(schema, key)
	if err != nil {
		return nil, err
	}

	kv := make(GSetting)
	ev, ok := gs[schema]
	if ok {
		for k, v := range ev {
			kv[k] = v
		}
	}

	kv[key] = val
	gs[schema] = kv

	return gs, nil
}

// ListKeys - lists the keys for the given schema
// returns the keys and any possible error.
func (Gs) ListKeys(schema string) ([]string, error) {
	gsCmd := newDistroBoxCmd(gs)
	rawKeys, err := cmder.New(gsCmd...).Args("list-keys", schema).CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("%s", string(rawKeys))
	}
	sc := bufio.NewScanner(strings.NewReader(string(rawKeys)))
	keys := []string{}
	for sc.Scan() {
		keys = append(keys, sc.Text())
	}

	return keys, nil
}

// ReadBackup - reads the backup file
// returns the gsettings stored in the backup file and any possible error.
func (Gs) ReadBackup() (GSettings, error) {
	gs := GSettings{}

	bu, err := os.ReadFile(gsBackupFile)
	if err != nil {
		panic(err)
	}

	err = yaml.Unmarshal(bu, &gs)
	if err != nil {
		return nil, err
	}

	return gs, nil
}

// Restore - restore all gsettings from backup file.
func (g Gs) Restore() error {
	mg.Deps(Gs.installed)

	var err error
	gs, err := g.ReadBackup()
	if err != nil {
		return err
	}

	for schema, keys := range gs {
		fmt.Printf("[ %s ]\n", schema)
		for key, val := range keys {
			err = g.Set(fmt.Sprintf("%s.%s", schema, key), val)
			if err != nil {
				return err
			}
		}
	}

	return nil
}

func (Gs) schemaKeySplit(scope string) (string, string, error) {
	li := strings.LastIndex(scope, ".")
	if li <= 0 {
		return "", "", fmt.Errorf(
			"invalid input, must be valid gsettings schema.value separated by dots (.)",
		)
	}

	schema := scope[:li]
	key := scope[li+1:]

	return schema, key, nil
}

// Set - set a given schema.key val.
func (g Gs) Set(scope string, val string) error {
	mg.Deps(Gs.installed)

	schema, key, err := g.schemaKeySplit(scope)
	if err != nil {
		return err
	}

	gsCmd := newDistroBoxCmd(gs)
	out, err := cmder.New(gsCmd...).Args("set", schema, key, val).Silent().CombinedOutput()
	if err != nil {
		return fmt.Errorf(
			"err setting: '%s' '%s' '%s'\n '%s'",
			schema,
			key,
			val,
			strings.TrimSpace(string(out)),
		)
	}

	return g.Backup(scope)
}

// WriteBackup - write given gsettings to backup file.
func (Gs) WriteBackup(gs GSettings) error {
	var err error
	var b bytes.Buffer

	yamlEncoder := yaml.NewEncoder(&b)
	yamlEncoder.SetIndent(indent)

	err = yamlEncoder.Encode(&gs)
	if err != nil {
		return err
	}

	err = os.WriteFile(gsBackupFile, b.Bytes(), 0600)
	if err != nil {
		return err
	}

	return nil
}
