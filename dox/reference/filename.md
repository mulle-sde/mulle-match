# filename

Find the patternfile that matches a filename.

## Synopsis

```bash
mulle-match filename [options] <filename>
```

## Description

The `filename` command tests a specific filename against the patternfiles to determine which patternfile matches it. This is useful for debugging pattern matching behavior and understanding how files are categorized.

The command can test against:
- All available patternfiles (default behavior)
- A specific patternfile using `-f`
- A custom pattern using `-p`

## Options

| Option | Description |
|--------|-------------|
| `-f <patternfile>` | Test against a specific patternfile |
| `-p <pattern>` | Test against a custom pattern |
| `-q <qualifier>` | Filter results with qualifier expression |
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# Test which patternfile matches a C source file
mulle-match filename src/main.c

# Test which patternfile matches a header file
mulle-match filename include/project.h
```

### Specific Patternfile Testing
```bash
# Test against a specific patternfile
mulle-match filename -f 50-source--sources src/main.c

# Check if a file matches the sources patternfile
mulle-match filename -f sources src/main.c
```

### Custom Pattern Testing
```bash
# Test against a custom pattern
mulle-match filename -p "*.c" src/main.c

# Test with glob patterns
mulle-match filename -p "src/**/*.c" src/main/main.c
```

### Advanced Pattern Testing
```bash
# Test with complex patterns
mulle-match filename -p "*[_-]test*.c" src/test_main.c

# Test header file patterns
mulle-match filename -p "*[_-]private.h" include/private_impl.h
```

## Pattern Syntax

The command supports .gitignore-style patterns:

### Basic Patterns
- `*` - Matches any sequence of characters (except path separators)
- `?` - Matches any single character
- `[abc]` - Matches any character in the set

### Path Patterns
- `**` - Matches any number of path segments
- `/**/` - Matches zero or more directories
- `/*/` - Matches exactly one directory

### Negation
- `!pattern` - Excludes files matching the pattern

### Examples
```bash
# Match all C files in any directory
mulle-match filename -p "**/*.c" src/lib/main.c

# Match files starting with 'test'
mulle-match filename -p "test*" test_main.c

# Match files in src directory
mulle-match filename -p "src/*" src/main.c
```

## Output

### Match Found
```
Match
50-source--sources
```

### No Match Found
```
No match
```

### Verbose Output
When using qualifiers or specific patternfiles, the output shows detailed matching information.

## Troubleshooting

### No Match When Expected
- Check patternfile contents: `mulle-match patternfile cat <name>`
- Verify filename matches `MULLE_MATCH_FILENAMES`
- Test with simpler patterns first

### Unexpected Match
- Use `-f` to test against specific patternfiles
- Check for overlapping patterns in patternfiles
- Review patternfile priority order

### Pattern Syntax Issues
- Use `**` for recursive directory matching
- Remember that `*` doesn't match path separators
- Test patterns incrementally

## Integration with Other Commands

### Debugging Pattern Matching
```bash
# Find out why a file isn't categorized as expected
mulle-match filename src/odd_file.txt

# Check all patternfiles for a specific file
mulle-match patternfile list
for pf in $(mulle-match patternfile list --names); do
    echo "Testing $pf:"
    mulle-match filename -f "$pf" src/file.c
done
```

### Pattern Development
```bash
# Test custom patterns during development
mulle-match filename -p "test_*.c" test_main.c

# Verify patternfile changes
mulle-match patternfile cat sources
mulle-match filename -f sources newfile.c
```

## See Also

- [`list`](list.md) - List files matching patternfiles
- [`patternfile`](patternfile.md) - Manage patternfiles
- [`init`](init.md) - Initialize patternfiles