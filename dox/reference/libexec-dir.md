# libexec-dir

Print the path to mulle-match's libexec directory.

## Synopsis

```bash
mulle-match libexec-dir
```

## Description

The `libexec-dir` command (also accessible as `library-path`) displays the absolute path to mulle-match's libexec directory. This directory contains internal scripts and supporting files used by mulle-match.

This command is primarily useful for:
- Debugging and troubleshooting
- Integration with other tools
- Understanding mulle-match's installation structure
- Script development that needs to reference mulle-match internals

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# Display the libexec directory path
mulle-match libexec-dir
```

### Script Integration
```bash
#!/bin/bash
# Get the libexec directory for script development
LIBEXEC_DIR=$(mulle-match libexec-dir)
echo "Mulle-match libexec directory: $LIBEXEC_DIR"

# List contents of libexec directory
ls -la "$LIBEXEC_DIR"
```

### Debugging
```bash
# Check if libexec directory exists and is accessible
if [ -d "$(mulle-match libexec-dir)" ]; then
    echo "Libexec directory is accessible"
else
    echo "Libexec directory is not accessible"
fi
```

## Output Format

The command outputs a single line containing the absolute path:
```
/usr/local/libexec/mulle-match
```

## How It Works

The libexec-dir command simply prints the value of the `MULLE_MATCH_LIBEXEC_DIR` environment variable, which is set during mulle-match's initialization.

## Use Cases

### Development and Debugging
```bash
# Examine internal scripts
find "$(mulle-match libexec-dir)" -name "*.sh" | head -5

# Check for specific internal files
ls "$(mulle-match libexec-dir)/mulle-match-"*
```

### Integration Scripts
```bash
# Source internal functions (if appropriate)
LIBEXEC_DIR=$(mulle-match libexec-dir)
# Note: Only source files that are documented as safe to use
```

### Build System Integration
```bash
# Use in Makefiles or build scripts
MULLE_MATCH_LIBEXEC:=$(shell mulle-match libexec-dir)
```

## Troubleshooting

### Empty Output
- Ensure mulle-match is properly installed
- Check that the installation is complete
- Verify environment variables are set correctly

### Permission Issues
- Check read permissions on the libexec directory
- Ensure mulle-match has proper access to its installation directory

### Path Issues
- Verify that the path exists: `ls -la "$(mulle-match libexec-dir)"`
- Check for symbolic links or mount points
- Ensure the installation wasn't corrupted

## Security Considerations

- The libexec directory contains internal implementation files
- These files are not part of the public API
- Direct use of internal files may break with future versions
- Always prefer documented command-line interfaces over direct file access

## See Also

- [`version`](version.md) - Show version information
- [`uname`](uname.md) - Show system information
- [`patternfile`](patternfile.md) - Manage patternfiles