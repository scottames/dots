package helpers

import "github.com/scottames/cmder"

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
