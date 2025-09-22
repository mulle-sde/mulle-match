# patternfile

## NAME

`mulle-match patternfile` - Manage patternfiles for file matching

## SYNOPSIS

```
mulle-match patternfile [options] <command> [arguments...]
```

## DESCRIPTION

The `patternfile` command is a comprehensive tool for managing patternfiles used by mulle-match to categorize and filter files. Patternfiles are .gitignore-like files that contain patterns for matching filenames.

Patternfiles are organized into two directories:
- `match.d/` - Contains patternfiles used for matching files (positive matches)
- `ignore.d/` - Contains patternfiles used for ignoring files (negative matches)

Each patternfile has a filename format: `<priority>-<type>--<category>`

## OPTIONS

- `-i`, `--ignore` : Operate on ignore.d patternfiles instead of match.d
- `-h`, `--help` : Show help information

## COMMANDS

### add

Add a new patternfile.

**SYNOPSIS**
```
mulle-match patternfile add [options] <type> <filename>
```

**OPTIONS**
- `-i`, `--ignore` : Create ignore patternfile
- `-t <type>` : Specify the type (alternative to positional argument)
- `-c <category>` : Set category (default: "all" for match.d, "none" for ignore.d)
- `-p <priority>` : Set priority number (default: 50)
- `-f` : Force overwrite existing patternfile

**EXAMPLES**
```bash
# Add a patternfile for C source files
echo "*.c" | mulle-match patternfile add source -

# Add a patternfile with specific priority and category
echo "*.h" | mulle-match patternfile add -p 60 -c headers source -
```

### cat

Display the contents of a patternfile.

**SYNOPSIS**
```
mulle-match patternfile cat [patternfile]
```

**EXAMPLES**
```bash
# Show all patternfiles
mulle-match patternfile cat

# Show specific patternfile
mulle-match patternfile cat 50-source--all
```

### copy

Copy an existing patternfile.

**SYNOPSIS**
```
mulle-match patternfile copy [options] <source> [destination]
```

**OPTIONS**
- `-c <category>` : Change category in destination
- `-p <priority>` : Change priority in destination
- `-t <type>` : Change type in destination

### edit

Edit a patternfile with your default editor.

**SYNOPSIS**
```
mulle-match patternfile edit [options] <patternfile>
```

**OPTIONS**
- `-a <line>` : Non-interactively add line to patternfile
- `-e <editor>` : Specify editor (default: $EDITOR or vi)
- `-t <template>` : Use template patternfile for creation

**EXAMPLES**
```bash
# Edit a patternfile
mulle-match patternfile edit 50-source--all

# Add a line without opening editor
mulle-match patternfile edit -a "*.cpp" 50-source--all
```

### ignore

Add a specific file to the ignore list.

**SYNOPSIS**
```
mulle-match patternfile ignore <filename>
```

**DESCRIPTION**
Adds the specified filename to the hardcoded ignore patternfile `00-user--none` in the ignore.d directory.

**EXAMPLES**
```bash
# Ignore a specific file
mulle-match patternfile ignore temp.log
```

### list

List all patternfiles.

**SYNOPSIS**
```
mulle-match patternfile list [options]
```

**OPTIONS**
- `-c`, `--cat` : Also display contents of each patternfile
- `--no-output-file-marker` : Don't show '*' for user-edited files

**EXAMPLES**
```bash
# List all patternfiles
mulle-match patternfile list

# List with contents
mulle-match patternfile list --cat
```

### match

Add a specific file to a match patternfile.

**SYNOPSIS**
```
mulle-match patternfile match [options] <filename> <patternfile>
```

**DESCRIPTION**
Adds a specific filename to an existing patternfile in the match.d directory.

**OPTIONS**
- `-t <template>` : Use template for patternfile creation
- `-c <category>` : Category of target patternfile
- `-p <priority>` : Priority of target patternfile
- `-t <type>` : Type of target patternfile

**EXAMPLES**
```bash
# Add specific header to patternfile
mulle-match patternfile match "special.h" "80-headers--private"
```

### path

Show the filesystem path of a patternfile.

**SYNOPSIS**
```
mulle-match patternfile path [options] <patternfile>
```

**OPTIONS**
- `-c <category>` : Category of patternfile
- `-p <priority>` : Priority of patternfile
- `-t <type>` : Type of patternfile

**EXAMPLES**
```bash
# Get path of patternfile
mulle-match patternfile path 50-source--all
```

### remove

Remove a patternfile.

**SYNOPSIS**
```
mulle-match patternfile remove <patternfile>
```

**EXAMPLES**
```bash
# Remove a patternfile
mulle-match patternfile remove 50-source--all
```

### rename

Rename a patternfile.

**SYNOPSIS**
```
mulle-match patternfile rename [options] <source> [destination]
```

**OPTIONS**
- `-c <category>` : Change category in destination
- `-p <priority>` : Change priority in destination
- `-t <type>` : Change type in destination
- `--copy` : Copy instead of move

### repair

Repair symlinks to patternfiles.

**SYNOPSIS**
```
mulle-match patternfile repair [options]
```

**OPTIONS**
- `--add` : Add missing patternfiles

**DESCRIPTION**
Repairs broken symlinks and optionally adds missing patternfiles from the share directory.

### status

Check patternfile status.

**SYNOPSIS**
```
mulle-match patternfile status
```

**DESCRIPTION**
Shows which patternfiles have been modified, need repair, or are missing.

### test

Test all patternfiles against a filename.

**SYNOPSIS**
```
mulle-match patternfile test <filename>
```

**DESCRIPTION**
Tests the given filename against all patternfiles and shows which ones match.

### test-file

Test a specific patternfile against a filename.

**SYNOPSIS**
```
mulle-match patternfile test-file <patternfile> <filename>
```

**DESCRIPTION**
Tests a specific patternfile against the given filename.

## PATTERNFILE FORMAT

Patternfiles use .gitignore-style syntax:

```
# Comments start with #
*.c          # Match all .c files
*.h          # Match all .h files
!temp.*      # But not temp.* files
src/         # Match everything in src/ directory
```

## PATTERNFILE NAMING

Patternfiles follow the format: `<priority>-<type>--<category>`

- **Priority**: Number determining match order (lower numbers match first)
- **Type**: File type category (e.g., "source", "header", "resource")
- **Category**: Sub-category within type (e.g., "public", "private", "generated")

## ENVIRONMENT VARIABLES

- `MULLE_MATCH_ETC_DIR` : Directory containing user patternfiles
- `MULLE_MATCH_SHARE_DIR` : Directory containing system patternfiles

## EXAMPLES

### Basic Usage

```bash
# Initialize with default patternfiles
mulle-match init

# Add custom patternfile for TypeScript files
echo "*.ts" | mulle-match patternfile add typescript -

# List all patternfiles
mulle-match patternfile list

# Edit a patternfile
mulle-match patternfile edit 50-typescript--all
```

### Advanced Usage

```bash
# Create ignore patternfile for build artifacts
echo "build/" | mulle-match patternfile add -i build artifacts -

# Add specific file to ignore
mulle-match patternfile ignore .DS_Store

# Test pattern matching
mulle-match patternfile test myfile.c

# Show patternfile contents
mulle-match patternfile cat 50-source--all
```

## SEE ALSO

- [`mulle-match init`](init.md) - Initialize patternfiles
- [`mulle-match list`](list.md) - List matching files
- [`mulle-match filename`](filename.md) - Test filename matching