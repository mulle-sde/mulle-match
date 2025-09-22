# categories

List all available categories from installed patternfiles.

## Synopsis

```bash
mulle-match categories
```

## Description

The `categories` command displays a list of all unique categories found in the installed patternfiles. Categories are used to group related patternfiles by their purpose or type (e.g., "source", "header", "build", etc.).

This command is useful for:
- Discovering available file categories in your project
- Understanding how patternfiles are organized
- Debugging patternfile categorization issues

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# List all available categories
mulle-match categories
```

### Integration with Other Commands
```bash
# List files for a specific category
for category in $(mulle-match categories); do
    echo "Files in category: $category"
    mulle-match list --category-matches "$category"
done
```

### Patternfile Management
```bash
# Check which categories are available before adding patternfiles
mulle-match categories

# Add a patternfile for a new category
mulle-match patternfile add mycategory mypattern.pattern
mulle-match categories  # Should now include 'mycategory'
```

## Output Format

The command outputs one category per line:
```
source
header
build
test
documentation
```

## How It Works

The categories command:
1. Scans all installed patternfiles in the `match.d` directory
2. Extracts category information from patternfile names
3. Removes duplicates to show unique categories
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

### No Categories Listed
- Ensure patternfiles are properly installed: `mulle-match patternfile list`
- Check that patternfiles follow the naming convention
- Verify patternfile directory exists and is readable

### Missing Expected Categories
- Patternfiles may not be installed: `mulle-match patternfile install <patternfile>`
- Check patternfile naming matches expected format
- Verify patternfile contents are valid

### Duplicate Categories
- Multiple patternfiles may define the same category
- This is normal and expected behavior

## Integration Examples

### Script Automation
```bash
#!/bin/bash
# Process files by category
for category in $(mulle-match categories); do
    echo "Processing category: $category"
    # Process files in this category
    mulle-match list --category-matches "$category" | while read -r file; do
        echo "  $file"
    done
done
```

### Build System Integration
```bash
# Generate category-specific file lists for build systems
for category in $(mulle-match categories); do
    mulle-match list --category-matches "$category" > "${category}_files.txt"
done
```

### Quality Assurance
```bash
# Verify all expected categories are present
expected_categories=("source" "header" "test")
for expected in "${expected_categories[@]}"; do
    if mulle-match categories | grep -q "^${expected}$"; then
        echo "✓ Category '$expected' is available"
    else
        echo "✗ Category '$expected' is missing"
    fi
done
```

## See Also

- [`types`](types.md) - List available types from patternfiles
- [`patternfile`](patternfile.md) - Manage patternfiles
- [`list`](list.md) - List files with category filtering