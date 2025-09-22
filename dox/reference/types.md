# types

List all available types from installed patternfiles.

## Synopsis

```bash
mulle-match types
```

## Description

The `types` command displays a list of all unique types found in the installed patternfiles. Types represent specific file formats or languages within categories (e.g., "c", "objective-c", "markdown", etc.).

This command is useful for:
- Discovering supported file types in your project
- Understanding patternfile type coverage
- Debugging type-based pattern matching issues

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# List all available types
mulle-match types
```

### Integration with Other Commands
```bash
# List files of a specific type
for type in $(mulle-match types); do
    echo "Files of type: $type"
    mulle-match list --type-matches "$type"
done
```

### Patternfile Management
```bash
# Check which types are available before adding patternfiles
mulle-match types

# Add a patternfile for a new type
mulle-match patternfile add source mytype mypattern.pattern
mulle-match types  # Should now include 'mytype'
```

## Output Format

The command outputs one type per line:
```
c
objective-c
markdown
shell
makefile
```

## How It Works

The types command:
1. Scans all installed patternfiles in the `match.d` directory
2. Extracts type information from patternfile names
3. Removes duplicates to show unique types
4. Outputs the sorted list

## Patternfile Naming Convention

Patternfiles follow the naming convention: `NNN-category--type`
- `NNN`: Priority number (determines matching order)
- `category`: The category this patternfile belongs to
- `type`: The specific type within the category

Example patternfile names:
- `50-source--c` (category: "source", type: "c")
- `50-source--objective-c` (category: "source", type: "objective-c")
- `60-header--c` (category: "header", type: "c")

## Troubleshooting

### No Types Listed
- Ensure patternfiles are properly installed: `mulle-match patternfile list`
- Check that patternfiles follow the naming convention
- Verify patternfile directory exists and is readable

### Missing Expected Types
- Patternfiles may not be installed: `mulle-match patternfile install <patternfile>`
- Check patternfile naming matches expected format
- Verify patternfile contents are valid

### Duplicate Types
- Multiple patternfiles may define the same type
- This is normal and expected behavior

## Integration Examples

### Script Automation
```bash
#!/bin/bash
# Process files by type
for type in $(mulle-match types); do
    echo "Processing type: $type"
    # Process files of this type
    mulle-match list --type-matches "$type" | while read -r file; do
        echo "  $file"
    done
done
```

### Build System Integration
```bash
# Generate type-specific file lists for build systems
for type in $(mulle-match types); do
    mulle-match list --type-matches "$type" > "${type}_files.txt"
done
```

### Quality Assurance
```bash
# Verify all expected types are present
expected_types=("c" "objective-c" "markdown")
for expected in "${expected_types[@]}"; do
    if mulle-match types | grep -q "^${expected}$"; then
        echo "✓ Type '$expected' is available"
    else
        echo "✗ Type '$expected' is missing"
    fi
done
```

## Relationship to Categories

Types and categories work together:
- **Categories** group related patternfiles by purpose (source, header, test)
- **Types** specify the specific format within a category (c, objective-c, markdown)

A patternfile like `50-source--c` belongs to:
- Category: "source"
- Type: "c"

## See Also

- [`categories`](categories.md) - List available categories from patternfiles
- [`patternfile`](patternfile.md) - Manage patternfiles
- [`list`](list.md) - List files with type filtering