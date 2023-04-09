package helpers_test

import (
	"bytes"
	"errors"
	"io"
	"os"
	"os/exec"
	"path"
	"strings"
	"testing"

	"github.com/scottames/dots/pkg/helpers"
)

func TestCat(t *testing.T) {
	// create a temporary file and write some content to it
	content := "hello, world!"
	tmpfile, err := os.CreateTemp("", "testfile")
	if err != nil {
		t.Fatalf("Failed to create temporary file: %v", err)
	}
	defer os.Remove(tmpfile.Name())
	if _, writeStrErr := tmpfile.WriteString(content); writeStrErr != nil {
		t.Fatalf("Failed to write content to temporary file: %v", writeStrErr)
	}

	// capture stdout to check the output of cat command
	oldStdout := os.Stdout
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatalf("Failed to create pipe for stdout: %v", err)
	}
	defer r.Close()
	defer w.Close()
	os.Stdout = w

	// call the Cat function with the temporary file path
	if catErr := helpers.Cat(tmpfile.Name()); catErr != nil {
		t.Fatalf("Cat failed with error: %v", catErr)
	}

	// restore stdout
	os.Stdout = oldStdout
	w.Close()

	// read the output from the pipe and check if it matches the file content
	var buf bytes.Buffer
	_, err = io.Copy(&buf, r)
	if err != nil {
		t.Fatalf("Failed to copy content from pipe: %v", err)
	}
	if got := buf.String(); got != content {
		t.Errorf("Unexpected output from cat command. Got %q, want %q", got, content)
	}
}

func TestWhich(t *testing.T) {
	// get existing binary
	bin := exec.Command("ls")
	if errors.Is(bin.Err, exec.ErrDot) {
		bin.Err = nil
	}

	// Test for an existing binary
	out, err := helpers.Which(path.Base(bin.Path))
	if err != nil {
		t.Errorf("Failed to find %s: %s", bin, err)
	}

	if !strings.Contains(out, bin.Path) {
		t.Errorf("Expected output to contain '%s', but got: %s", bin.Path, out)
	}

	// Test for a non-existent binary
	nonBin := "nonexistent"
	_, err = helpers.Which(nonBin)
	if err == nil {
		t.Errorf("Expected error for non-existent binary: %s", bin)
	}
}
