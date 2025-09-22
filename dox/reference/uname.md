# uname

Display mulle-match's simplified uname information.

## Synopsis

```bash
mulle-match uname
```

## Description

The `uname` command displays mulle-match's simplified uname(1) output. This provides basic system identification information in a format consistent with mulle-match's environment.

This command is useful for:
- System identification and compatibility checking
- Debugging environment-specific issues
- Script automation that needs to detect the platform
- Logging and diagnostic purposes

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# Display system information
mulle-match uname
```

### Script Integration
```bash
#!/bin/bash
# Check system type in scripts
SYSTEM=$(mulle-match uname)
echo "Running on: $SYSTEM"

case "$SYSTEM" in
    linux*)
        echo "Linux-specific configuration"
        ;;
    darwin*)
        echo "macOS-specific configuration"
        ;;
    *)
        echo "Other system: $SYSTEM"
        ;;
esac
```

### Logging and Diagnostics
```bash
# Include system info in diagnostic output
echo "System: $(mulle-match uname)"
echo "Version: $(mulle-match version)"
echo "Libexec: $(mulle-match libexec-dir)"
```

## Output Format

The command outputs a simplified uname string:
```
linux
darwin
mingw
```

## How It Works

The uname command prints the value of the `MULLE_UNAME` environment variable, which is set during mulle-match's initialization to provide a simplified platform identifier.

## Platform Values

Common values include:
- `linux` - Linux systems
- `darwin` - macOS systems
- `mingw` - Windows systems (MinGW)
- `freebsd` - FreeBSD systems
- `openbsd` - OpenBSD systems

## Use Cases

### Platform-Specific Logic
```bash
# Adjust behavior based on platform
if [ "$(mulle-match uname)" = "darwin" ]; then
    # macOS-specific code
    echo "Running on macOS"
elif [ "$(mulle-match uname)" = "linux" ]; then
    # Linux-specific code
    echo "Running on Linux"
fi
```

### Build System Integration
```bash
# Use in Makefiles for platform detection
PLATFORM:=$(shell mulle-match uname)

ifeq ($(PLATFORM), darwin)
    CFLAGS += -DMULLE_MATCH_DARWIN
endif
```

### Diagnostic Scripts
```bash
#!/bin/bash
# Collect system information for bug reports
cat << EOF
System Information:
- Platform: $(mulle-match uname)
- Version: $(mulle-match version)
- Date: $(date)
EOF
```

## Comparison with Standard uname

| Command | Output | Purpose |
|---------|--------|---------|
| `uname` | `Linux` | Standard system name |
| `mulle-match uname` | `linux` | Simplified, lowercase identifier |

The mulle-match version:
- Uses lowercase for consistency
- Provides simplified identifiers
- Is guaranteed to be available in mulle environments
- Follows mulle naming conventions

## Troubleshooting

### Empty Output
- Ensure mulle-match is properly installed
- Check that environment variables are set during initialization
- Verify the installation is complete

### Unexpected Values
- Check if running in a container or cross-compilation environment
- Verify the platform detection logic in mulle-bashfunctions
- Compare with standard `uname -s` output

### Platform Detection Issues
- Some platforms may have different identifiers
- Check the mulle-bashfunctions documentation for platform mappings
- Report issues if platform detection seems incorrect

## See Also

- [`version`](version.md) - Show version information
- [`libexec-dir`](libexec-dir.md) - Show libexec directory path
- [`patternfile`](patternfile.md) - Manage patternfiles