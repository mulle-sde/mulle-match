# list

List files that match the rules contained in the patternfiles.

## Synopsis

```bash
mulle-match list [options]
```

## Description

The `list` command searches for files that match patterns defined in patternfiles. It recursively searches through directories specified by `MULLE_MATCH_PATH`, excluding directories listed in `MULLE_MATCH_IGNORE_PATH`, and only considers filenames that match `MULLE_MATCH_FILENAMES`.

This is the default command when no command is specified.

## Options

### Output Format Options
| Option | Description |
|--------|-------------|
| `-f <format>` | Specify output format (see format specifiers below) |
| `-l` | Use long format showing type, category, and basename |
| `--locations` | Override search locations |

### Filtering Options
| Option | Description |
|--------|-------------|
| `-q <qualifier>` | Filter by qualifier expression |
| `-cq <pattern>` | Filter by category matching pattern |
| `-tq <pattern>` | Filter by type matching pattern |

### Git Integration Options
| Option | Description |
|--------|-------------|
| `--gitignore` | Use .gitignore to prune search tree |
| `--gitignore-only` | Only list files, ignore patternfiles |
| `--no-gitignore` | Disable gitignore integration |

### Search Control Options
| Option | Description |
|--------|-------------|
| `--follow` | Follow symlinks (default) |
| `--no-follow` | Don't follow symlinks |
| `--ignore-path <path>` | Override ignore paths |
| `--match-names <pattern>` | Override filename patterns |
| `--find-option <option>` | Pass additional options to find command |

### Other Options
| Option | Description |
|--------|-------------|
| `-a`, `--all` | Include all file types (not just regular files) |
| `-u`, `--unsorted` | Don't sort output |
| `-h`, `--help` | Show help information |

## Format Specifiers

When using `-f <format>`, the following specifiers are available:

| Specifier | Description |
|-----------|-------------|
| `%b` | Basename of the file |
| `%i` | Basename as identifier |
| `%I` | Basename as uppercase identifier |
| `%c` | Category of file |
| `%C` | Category as uppercase |
| `%f` | Full filename |
| `%m` | Patternfile name |
| `%p` | Patternfile path |
| `%t` | Type of file |
| `%T` | Type as uppercase |
| `\\n` | Newline |

## Qualifier Language

The qualifier system supports complex filtering expressions:

### Basic Expressions
- `TYPE_MATCHES <pattern>` - Match files of specific type
- `CATEGORY_MATCHES <pattern>` - Match files in specific category

### Logical Operators
- `AND` - Logical AND
- `OR` - Logical OR
- `NOT` - Logical NOT
- `(expr)` - Grouping

### Examples
```bash
# Match source files
mulle-match list -q "TYPE_MATCHES source"

# Match header files in public category
mulle-match list -q "CATEGORY_MATCHES public AND TYPE_MATCHES header"

# Exclude test files
mulle-match list -q "NOT CATEGORY_MATCHES test"
```

## Environment Variables

### Search Control
| Variable | Description | Default |
|----------|-------------|---------|
| `MULLE_MATCH_PATH` | Colon-separated list of directories to search | `.` |
| `MULLE_MATCH_IGNORE_PATH` | Colon-separated list of directories to ignore | (empty) |
| `MULLE_MATCH_FILENAMES` | Filename patterns to consider | `*` |
| `MULLE_MATCH_FOLLOW_SYMLINK` | Whether to follow symlinks | `YES` |

## Examples

### Basic Usage
```bash
# List all matching files
mulle-match list

# List with detailed format
mulle-match list -l

# List with custom format
mulle-match list -f "%t/%c: %f\\n"
```

### Filtered Searches
```bash
# List only source files
mulle-match list -tq source

# List files in specific category
mulle-match list -cq header

# Complex filtering
mulle-match list -q "TYPE_MATCHES source AND NOT CATEGORY_MATCHES test"
```

### Directory-Specific Searches
```bash
# Search only in src directory
MULLE_MATCH_PATH="src" mulle-match list

# Search in multiple directories
MULLE_MATCH_PATH="src:test" mulle-match list

# Ignore build directory
MULLE_MATCH_IGNORE_PATH="build" mulle-match list
```

### Git Integration
```bash
# Use .gitignore for filtering
mulle-match list --gitignore

# List only files that would be ignored by git
mulle-match list --gitignore-only
```

### Advanced Examples
```bash
# Find C source files in src and foo/src
MULLE_MATCH_FILENAMES="*.c:*.h" \
MULLE_MATCH_PATH="src:foo/src" \
mulle-match list -tq source

# List files with patternfile information
mulle-match list -f "File: %f\\nPattern: %m\\n\\n"

# Process files with script
for file in $(mulle-match list --names); do
    echo "Processing: $file"
done
```

## Performance Considerations

- Use `MULLE_MATCH_IGNORE_PATH` to exclude large directories
- Limit `MULLE_MATCH_PATH` to specific directories when possible
- Use `MULLE_MATCH_FILENAMES` to filter by file extensions
- The command uses parallel processing for better performance on large directory trees

## Troubleshooting

### No Files Found
- Check `MULLE_MATCH_PATH` contains the correct directories
- Verify patternfiles exist: `mulle-match patternfile list`
- Check `MULLE_MATCH_FILENAMES` matches your files

### Unexpected Results
- Use `-f "%m: %f\\n"` to see which patternfile matched each file
- Test specific files: `mulle-match filename <file>`
- Check patternfile contents: `mulle-match patternfile cat <name>`

### Performance Issues
- Add large directories to `MULLE_MATCH_IGNORE_PATH`
- Use more specific `MULLE_MATCH_PATH` values
- Limit `MULLE_MATCH_FILENAMES` to relevant extensions

### Gitignore Issues
- Ensure `.gitignore` exists in current directory
- Check `.gitignore` syntax is correct
- Use `--no-gitignore` to disable if needed

## See Also

- [`init`](init.md) - Initialize patternfiles
- [`filename`](filename.md) - Test specific filename
- [`patternfile`](patternfile.md) - Manage patternfiles