# init

Setup some initial patternfiles for file matching.

## Synopsis

```bash
mulle-match init [options]
```

## Description

The `init` command initializes the current directory for mulle-match file matching by installing some demo patternfiles. These patternfiles provide basic categorization for common file types in C and Objective-C projects.

The command creates three initial patternfiles:
- **private-headers**: Matches private header files (`*[_-]private.h`, `*[_-]private.inc`, `private.h`, `private.inc`)
- **public-headers**: Matches public header files (`*.h`)
- **sources**: Matches source files (`*.[cm]`)

## Options

| Option | Description |
|--------|-------------|
| `-d <directory>` | Use the specified directory instead of the current working directory |
| `-h`, `--help` | Show help information |

## Examples

### Basic Initialization
```bash
# Initialize patternfiles in current directory
mulle-match init
```

### Initialize in Specific Directory
```bash
# Initialize patternfiles in a specific directory
mulle-match init -d /path/to/project
```

### Verify Initialization
```bash
# List the created patternfiles
mulle-match patternfile list

# View contents of a patternfile
mulle-match patternfile cat sources
```

## Patternfile Details

After initialization, the following patternfiles are created:

### private-headers
```
*[_-]private.h
*[_-]private.inc
private.h
private.inc
```

### public-headers
```
*.h
```

### sources
```
*.[cm]
```

## Integration with Other Commands

After initialization, you can:
- **Test matching**: `mulle-match filename test.c`
- **List matches**: `mulle-match list`
- **Modify patterns**: Edit patternfiles and reinstall
- **Add more patterns**: `mulle-match patternfile add <type> <file>`

## Troubleshooting

### Patternfiles Not Created
If patternfiles are not created, check:
- Write permissions in the target directory
- Whether patternfiles already exist (use `--force` if needed)

### Directory Issues
- Ensure the target directory exists and is writable
- Use absolute paths if relative paths don't work as expected

### Existing Patternfiles
If patternfiles already exist, the command will not overwrite them. Use `mulle-match patternfile remove` to clean up first if needed.

## See Also

- [`list`](list.md) - List files matching patternfiles
- [`filename`](filename.md) - Test filename against patternfiles
- [`patternfile`](patternfile.md) - Manage patternfiles