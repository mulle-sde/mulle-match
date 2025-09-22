# mulle-match Command Reference

## Overview

**mulle-match** is a command-line tool for matching filenames against .gitignore-like patternfiles to categorize and type files according to their filenames and location. It provides a structured way to define patternfiles and test filename matching in the Mulle ecosystem.

## Command Categories

### Core Operations
- **[`init`](init.md)** - Setup some initial patternfiles
- **[`list`](list.md)** - List files that match patternfiles (default)
- **[`filename`](filename.md)** - Find the patternfile that matches a filename
- **[`clean`](clean.md)** - Remove cached patternfiles

### Pattern Management
- **[`patternfile`](patternfile.md)** - Manage patternfiles

### Utility Commands
- **[`categories`](categories.md)** - List available categories from patternfiles
- **[`types`](types.md)** - List available types from patternfiles
- **[`libexec-dir`](libexec-dir.md)** - Print path to mulle-match libexec
- **[`uname`](uname.md)** - mulle-match's simplified uname(1)
- **[`version`](version.md)** - Show version information

## Quick Start Examples

### Basic Pattern Management
```bash
# Initialize patternfiles
mulle-match init

# List all patternfiles
mulle-match patternfile list

# Test a filename against patternfiles
mulle-match filename myfile.svg
```

### File Matching
```bash
# List files matching patternfiles
mulle-match list

# List files with specific patternfile filter
mulle-match list --match-filter svg

# Display patternfile contents
mulle-match patternfile cat svg
```

### Advanced Operations
```bash
# Install patternfile to ignore directory
mulle-match patternfile install -i build build.pattern

# Remove a patternfile
mulle-match patternfile remove svg

# List available categories
mulle-match categories

# List available types
mulle-match types
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `init` | Core | Setup some initial patternfiles |
| `list` | Core | List files that match patternfiles (default) |
| `filename` | Core | Find the patternfile that matches a filename |
| `clean` | Core | Remove cached patternfiles |
| `patternfile` | Pattern | Manage patternfiles |
| `categories` | Utility | List available categories from patternfiles |
| `types` | Utility | List available types from patternfiles |
| `libexec-dir` | Utility | Print path to mulle-match libexec |
| `uname` | Utility | mulle-match's simplified uname(1) |
| `version` | Utility | Show version information |

## Getting Help

### Command Help
```bash
# Get help for a specific command
mulle-match <command> --help

# List all available commands
mulle-match --help

# Get detailed command information
mulle-match <command> --help --verbose
```

### Documentation
- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check patternfile contents with `mulle-match patternfile cat`

## Common Workflows

### Setting Up Patternfiles
1. **Initialize** patternfiles: `mulle-match init`
2. **Add** patternfiles: `mulle-match patternfile add <type> <file>`
3. **Test** matching: `mulle-match filename <testfile>`
4. **List** matches: `mulle-match list`

### Managing Patternfiles
1. **List** patternfiles: `mulle-match patternfile list`
2. **View** contents: `mulle-match patternfile cat <type>`
3. **Modify** patternfiles: Edit files and reinstall
4. **Remove** unused: `mulle-match patternfile remove <type>`

### File Categorization
1. **Define** patterns: Create patternfiles for file types
2. **Install** patternfiles: `mulle-match patternfile install <type> <file>`
3. **Test** matching: `mulle-match filename <file>`
4. **Process** files: Use `mulle-match list` for batch operations

## Troubleshooting

### Common Issues
```bash
# Check patternfile syntax
mulle-match patternfile cat <type>

# Test specific filename
mulle-match filename <problematic-file>

# List all matching files
mulle-match list --verbose
```

### Pattern Problems
```bash
# Verify patternfile exists
mulle-match patternfile list

# Check patternfile contents
mulle-match patternfile cat <type>

# Test pattern matching
mulle-match filename --pattern "*.ext" test.ext
```

### Configuration Issues
```bash
# Reinitialize patternfiles
mulle-match init

# Check environment variables
echo $MULLE_MATCH_PATH
echo $MULLE_MATCH_IGNORE_PATH
```

## Advanced Usage

### Custom Patternfiles
```bash
# Create custom patternfile
echo "*.custom" > custom.pattern
echo "!important.custom" >> custom.pattern
mulle-match patternfile add custom custom.pattern
```

### Environment Variables
```bash
# Set search paths
export MULLE_MATCH_PATH="src:dox"

# Set ignore paths
export MULLE_MATCH_IGNORE_PATH="build:.git"

# Set filename wildcards
export MULLE_MATCH_FILENAMES="*.c:*.h:*.m"
```

### Integration with Scripts
```bash
# Process matching files
for file in $(mulle-match list --names); do
   echo "Processing: $file"
done

# Export patternfile list
mulle-match patternfile list > patternfiles.txt
```

## Related Documentation

- **[TODO.md](TODO.md)** - Current development status and process guide
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines
- **[mulle-fetch.md](../mulle-fetch.md)** - Fetching and cloning documentation