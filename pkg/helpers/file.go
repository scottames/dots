package helpers

import (
	"fmt"
	"os"
	"path"

	"github.com/scottames/cmder"
)

// IsDir - returns true if given directory exists or an error.
func IsDir(path string) (bool, error) {
	fileInfo, err := os.Stat(path)
	if err != nil {
		return false, err
	}

	return fileInfo.IsDir(), err
}

// Exists - returns true if file or dir exists
//   - see SymlinkExists for symlinks
func Exists(path string) bool {
	_, err := os.Stat(path)
	if err != nil {
		return os.IsExist(err)
	}
	return true
}

// SymlinkExists - returns true if symlink exists
//   - see Exists for files & dirs
func SymlinkExists(symlink string) bool {
	target, err := os.Lstat(symlink)
	if err != nil {
		return false
	}
	/*
	   target.Mode() returns a bitmask representing the file mode and permission bits for the file
	   if the os.ModeSymlink bit is set in this bitmask, that indicates that the file is a symbolic link
	   this checks if the os.ModeSymlink bit is set in the mode bits of the file at symlink
	     indicating that it is a symbolic link
	*/
	if target.Mode()&os.ModeSymlink != os.ModeSymlink {
		return false
	}

	return true
}

// CreateSymlinks creates a set of symlinks and returns an error if any issues are encountered
// - forces replacement of existing links.
func CreateSymlinks(sls map[string]string, ignoreErr bool) error {
	for file, symlink := range sls {
		// Check if symlink already exists
		if SymlinkExists(symlink) {
			fmt.Printf("Removing existing link: %s\n", symlink)
			if err := os.Remove(symlink); err != nil {
				return fmt.Errorf("unable to remove existing link %s: %w", symlink, err)
			}
			if SymlinkExists(symlink) {
				return fmt.Errorf("unable to remove existing link %s", symlink)
			}
		}

		// Create new symlink
		fmt.Printf("Linking: %s -> %s\n", symlink, file)
		err := os.Symlink(file, symlink)
		if err != nil {
			if ignoreErr {
				fmt.Printf("Ignoring error: %s\n", err.Error())
			} else {
				return fmt.Errorf("unable to create symlink %s -> %s: %w", symlink, file, err)
			}
		}
	}

	return nil
}

// ListDirs - returns sub-directories in the given (target) directory and a possible error.
func ListDirs(target string) ([]string, error) {
	files, err := os.ReadDir(target)
	if err != nil {
		return nil, fmt.Errorf("cannot read dir: %w", err)
	}

	dirs := []string{}
	for _, fileInfo := range files {
		if fileInfo.IsDir() {
			dirs = append(dirs, fileInfo.Name())
		}
	}
	return dirs, nil
}

// SetupEnvRCs - symlink & `direnv allow` .envrc files.
func SetupEnvRCs(sls map[string]string, ignoreErr bool) error {
	const direnv = "direnv"
	if _, err := Which(direnv); err != nil {
		return fmt.Errorf("unable to find %s in path", direnv)
	}

	err := CreateSymlinks(sls, ignoreErr)
	if err != nil && !ignoreErr {
		return err
	}
	for _, v := range sls {
		err = cmder.New(direnv, "allow").Dir(path.Dir(v)).Run()
		if err != nil && !ignoreErr {
			return err
		}
	}
	return nil
}
