# version

Display mulle-match version information.

## Synopsis

```bash
mulle-match version
```

## Description

The `version` command displays the version number of the mulle-match executable. This is useful for:

- Checking which version of mulle-match is installed
- Troubleshooting version-specific issues
- Script automation that needs version information
- Bug reporting and support requests

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# Display version information
mulle-match version
```

### Script Integration
```bash
#!/bin/bash
# Check version in scripts
VERSION=$(mulle-match version)
echo "Mulle-match version: $VERSION"

# Version comparison
if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Valid version format"
fi
```

### Diagnostic Output
```bash
# Include version in diagnostic information
echo "Mulle-match version: $(mulle-match version)"
echo "System: $(mulle-match uname)"
echo "Libexec: $(mulle-match libexec-dir)"
```

## Output Format

The command outputs the version string:
```
3.0.0
```

## How It Works

The version command prints the value of the `MULLE_EXECUTABLE_VERSION` environment variable, which is set at build time to reflect the current version of mulle-match.

## Version Format

Mulle-match uses semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

## Use Cases

### Version Checking in Scripts
```bash
#!/bin/bash
# Ensure minimum version requirement
REQUIRED_VERSION="3.0.0"
CURRENT_VERSION=$(mulle-match version)

if [ "$CURRENT_VERSION" != "$REQUIRED_VERSION" ]; then
    echo "Warning: Expected version $REQUIRED_VERSION, got $CURRENT_VERSION"
fi
```

### Build System Integration
```bash
# Use in Makefiles
MULLE_MATCH_VERSION:=$(shell mulle-match version)
```

### Logging and Debugging
```bash
# Include version in log files
echo "$(date): mulle-match $(mulle-match version) started" >> /var/log/mulle-match.log
```

### Support and Bug Reports
```bash
# Collect version information for bug reports
cat << EOF > bug_report.txt
Mulle-match version: $(mulle-match version)
System: $(mulle-match uname)
Date: $(date)
Description: [describe the issue]
EOF
```

## Troubleshooting

### Empty Output
- Ensure mulle-match is properly installed
- Check that the executable is not corrupted
- Verify environment variables are set correctly

### Unexpected Version
- Check if running from a development build
- Verify the installation source (release vs development)
- Compare with expected version for your use case

### Version Format Issues
- Some development versions may have different formats
- Check the build system for version format consistency
- Report if version format seems incorrect

## Comparison with Other Version Commands

| Command | Output | Purpose |
|---------|--------|---------|
| `mulle-match version` | `3.0.0` | Mulle-match specific version |
| `mulle-match --version` | `3.0.0` | Alternative version access |
| `mulle-sde version` | Varies | Build system version |

## See Also

- [`uname`](uname.md) - Show system information
- [`libexec-dir`](libexec-dir.md) - Show libexec directory path
- [`patternfile`](patternfile.md) - Manage patternfiles