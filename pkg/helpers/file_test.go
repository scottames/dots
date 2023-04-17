package helpers_test

import (
	"os"
	"path"
	"path/filepath"
	"testing"

	"golang.org/x/exp/slices"

	"github.com/scottames/dots/pkg/helpers"
)

func TestIsDir(t *testing.T) {
	// Create a temporary directory for testing
	tempDir := t.TempDir()

	// Test a directory that exists
	exists, err := helpers.IsDir(tempDir)
	if err != nil {
		t.Errorf("IsDir(%q) returned an error: %s", tempDir, err)
	}
	if !exists {
		t.Errorf("IsDir(%q) = %t, expected true", tempDir, exists)
	}

	// Test a directory that doesn't exist
	doesntExist := path.Join(tempDir, "nonexistent")
	exists, err = helpers.IsDir(doesntExist)
	if err == nil {
		t.Errorf("IsDir(%q) returned nil error, expected an error", doesntExist)
	}
	if exists {
		t.Errorf("IsDir(%q) = %t, expected false", doesntExist, exists)
	}

	// Test a file that exists
	filePath := path.Join(tempDir, "testfile.txt")
	file, err := os.Create(filePath)
	if err != nil {
		t.Errorf("Failed to create test file: %s", err)
	}
	file.Close()
	exists, err = helpers.IsDir(filePath)
	if err != nil {
		t.Errorf("IsDir(%q) returned an error: %s", tempDir, err)
	}
	if exists {
		t.Errorf("IsDir(%q) = %t, expected false", filePath, exists)
	}
}

func TestExists(t *testing.T) {
	// Create a temporary file for testing
	tempFile, err := os.CreateTemp("", "testfile")
	if err != nil {
		t.Errorf("Failed to create test file: %s", err)
	}
	tempFilePath := tempFile.Name()
	tempFile.Close()
	defer os.Remove(tempFilePath)

	// Test a file that exists
	exists := helpers.Exists(tempFilePath)
	if !exists {
		t.Errorf("Exists(%q) = %t, expected true", tempFilePath, exists)
	}

	// Test a file that doesn't exist
	doesntExist := "nonexistent.txt"
	exists = helpers.Exists(doesntExist)
	if exists {
		t.Errorf("Exists(%q) = %t, expected false", doesntExist, exists)
	}

	// Test a directory that exists
	tempDir, err := os.MkdirTemp("", "testdir")
	if err != nil {
		t.Errorf("Failed to create test directory: %s", err)
	}
	defer os.RemoveAll(tempDir)
	exists = helpers.Exists(tempDir)
	if !exists {
		t.Errorf("Exists(%q) = %t, expected true", tempDir, exists)
	}

	// Test a directory that doesn't exist
	doesntExistDir := "nonexistent-dir"
	exists = helpers.Exists(doesntExistDir)
	if exists {
		t.Errorf("Exists(%q) = %t, expected false", doesntExistDir, exists)
	}
}

func TestSymlinkExists(t *testing.T) {
	// Create a temporary file and symlink for testing
	tempFile, err := os.CreateTemp("", "testfile")
	if err != nil {
		t.Errorf("Failed to create test file: %s", err)
	}
	tempFilePath := tempFile.Name()
	tempFile.Close()
	defer os.Remove(tempFilePath)

	tempSymlinkPath := filepath.Join(filepath.Dir(tempFilePath), "testlink")
	err = os.Symlink(tempFilePath, tempSymlinkPath)
	if err != nil {
		t.Errorf("Failed to create test symlink: %s", err)
	}
	defer os.Remove(tempSymlinkPath)

	// Test a symlink that exists
	exists := helpers.SymlinkExists(tempSymlinkPath)
	if !exists {
		t.Errorf("SymlinkExists(%q) = %t, expected true", tempSymlinkPath, exists)
	}

	// Test a symlink that doesn't exist
	doesntExist := "nonexistent-link"
	exists = helpers.SymlinkExists(doesntExist)
	if exists {
		t.Errorf("SymlinkExists(%q) = %t, expected false", doesntExist, exists)
	}

	// Test a file that exists (should return not exists as it is not a symlink)
	exists = helpers.SymlinkExists(tempFilePath)
	if exists {
		t.Errorf("SymlinkExists(%q) = %t, expected false", tempFilePath, exists)
	}
}

func TestCreateSymlinks(t *testing.T) {
	// Create temporary files to use as the targets of the symlinks
	tmpDir, err := os.MkdirTemp("", "symlink_test")
	if err != nil {
		t.Fatalf("Failed to create temporary directory: %v", err)
	}

	defer os.RemoveAll(tmpDir)
	// Define the input data for the test
	input := map[string]string{
		"file1.txt": filepath.Join(tmpDir, "symlink1"),
		"file2.txt": filepath.Join(tmpDir, "symlink2"),
		"file3.txt": filepath.Join(tmpDir, "symlink3"),
	}

	for file := range input {
		_, createErr := os.Create(filepath.Join(tmpDir, file))
		if createErr != nil {
			t.Fatalf("Failed to create temporary file: %v", createErr)
		}
	}

	// Test creating symlinks
	err = helpers.CreateSymlinks(input, false)
	if err != nil {
		t.Errorf("CreateSymlinks failed with error: %v", err)
	}

	// Test creating symlinks with ignoreErr=true
	err = helpers.CreateSymlinks(map[string]string{"file3.txt": "/nonexistent/file"}, true)
	if err != nil {
		t.Errorf("CreateSymlinks failed with ignoreErr=true: %v", err)
	}

	// Test that errors are returned when ignoreErr=false
	err = helpers.CreateSymlinks(map[string]string{"file3.txt": "/nonexistent/file"}, false)
	if err == nil {
		t.Errorf("CreateSymlinks failed to return error")
	}
}

func TestListDirs(t *testing.T) {
	// Create temporary directory and sub-directories for testing
	tempDir, err := os.MkdirTemp("", "test")
	if err != nil {
		t.Fatalf("Failed to create temporary directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	subDirs := []string{"subdir1", "subdir2", "subdir3"}
	for _, subdir := range subDirs {
		err = os.MkdirAll(tempDir+"/"+subdir, os.ModePerm)
		if err != nil {
			t.Fatalf("Failed to create sub-directory: %v", err)
		}
	}

	// Call ListDirs function to get sub-directories
	dirs, err := helpers.ListDirs(tempDir)
	if err != nil {
		t.Fatalf("ListDirs returned an error: %v", err)
	}

	// Check if the returned sub-directories match the created sub-directories
	if len(dirs) != len(subDirs) {
		t.Errorf("Expected %d sub-directories, but got %d", len(subDirs), len(dirs))
	}
	for _, subdir := range subDirs {
		if !slices.Contains(dirs, subdir) {
			t.Errorf("Expected sub-directory %s, but not found in returned dirs", subdir)
		}
	}
}
