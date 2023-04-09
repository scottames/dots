package helpers

import (
	"fmt"
	"os"

	"github.com/scottames/cmder"
)

// Cat - read file and pipe contents to `cat`.
func Cat(f string) error {
	content, err := os.ReadFile(f)
	if err != nil {
		return err
	}

	return cmder.New("cat").Silent().In(content...).Run()
}

// Which - executes `which` against the given binary, returns the result and/or an error.
func Which(bin string) (string, error) {
	w, err := cmder.New("which", bin).Silent().CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("%s not found in path", bin)
	}
	return string(w), nil
}
