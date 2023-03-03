package cmd

import "github.com/spf13/cobra/doc"

// GenerateDoc generates cobra docs of the cmd bump
func GenerateDoc(path string) error {
	return doc.GenMarkdownTree(rootCmd, path)
}
