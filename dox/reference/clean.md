# clean

Remove cached patternfiles and housekeeping files.

## Synopsis

```bash
mulle-match clean
```

## Description

The `clean` command removes cached patternfiles and other housekeeping files created by mulle-match. This is useful for:

- Clearing stale cache data after patternfile changes
- Freeing disk space used by cached pattern matching results
- Ensuring fresh pattern matching after configuration changes
- Troubleshooting cache-related issues

The command safely removes the cache directory `${MULLE_MATCH_VAR_DIR}/cache/match` and all its contents.

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Cache Cleaning
```bash
# Remove all cached patternfiles
mulle-match clean
```

### Clean and Reinitialize
```bash
# Clean cache and reinitialize patternfiles
mulle-match clean
mulle-match init
```

### Troubleshooting Cache Issues
```bash
# If pattern matching seems incorrect, try cleaning cache
mulle-match clean
mulle-match list
```

## What Gets Cleaned

The clean command removes:
- Cached patternfile data in `${MULLE_MATCH_VAR_DIR}/cache/match`
- Compiled pattern matching results
- Temporary files created during pattern processing

## When to Use Clean

### After Patternfile Changes
```bash
# Edit a patternfile
edit patternfile.txt

# Clean cache to pick up changes
mulle-match clean

# Test the changes
mulle-match list
```

### Performance Issues
If mulle-match seems slow, cleaning the cache may help:
```bash
mulle-match clean
```

### Disk Space Management
To free up space used by cache files:
```bash
mulle-match clean
```

### Troubleshooting
If you suspect cache corruption:
```bash
mulle-match clean
mulle-match init
```

## Cache Location

The cache is stored in:
```
${MULLE_MATCH_VAR_DIR}/cache/match
```

Where `MULLE_MATCH_VAR_DIR` is typically:
- `~/.mulle/var/mulle-match` (user level)
- Or a project-specific location

## Safe Operation

The clean command:
- Uses `rmdir_safer` for safe directory removal
- Only removes mulle-match specific cache files
- Does not affect patternfile definitions
- Does not remove user-created files

## Integration with Other Commands

### Complete Reset
```bash
# Clean everything and start fresh
mulle-match clean
mulle-match patternfile remove --all
mulle-match init
```

### Development Workflow
```bash
# During patternfile development
mulle-match clean
mulle-match patternfile add test test.pattern
mulle-match filename test.c
```

## Troubleshooting

### Clean Doesn't Seem to Work
- Check that `MULLE_MATCH_VAR_DIR` is set correctly
- Verify write permissions to the cache directory
- Try running with verbose output

### Files Still Cached After Clean
- Some files may be locked by running processes
- Try again after closing other mulle-match instances
- Check for permission issues

### Clean Removes Too Much
The clean command only removes cache files, not:
- Patternfile definitions
- User configuration
- Installed patternfiles

## See Also

- [`init`](init.md) - Initialize patternfiles
- [`patternfile`](patternfile.md) - Manage patternfiles
- [`list`](list.md) - List files matching patternfiles