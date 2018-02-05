 🕵🏻‍ Extensible filesystem observation

... for Linux, OS X, FreeBSD, Windows

**mulle-monitor** watches changes in a folder (and subfolders) using
[fswatch]() or [inotifywait]() and then calls an appropriate callback script
based on user supplied filter rules.

![](dox/mulle-monitor-overview.png)



Executable      | Description
----------------|--------------------------------
`mulle-monitor` | Observe changes in filesystem and react by calling a script


## Commands

### mulle-monitor run

![](dox/mulle-monitor-run.png)

If you know how a [.gitignore](https://git-scm.com/docs/gitignore) file works,
you may rejoice as that's pretty similar to the way **mulle-monitor**
match and ignore files work.

Here is a simple file to match files with *.txt that reside in the doc folder.
But not those, that reside in and "old" folder inside.


```
/doc/*.txt
!old/*.txt
```

Files are ignored first, before they are matched.

* the `ignore.d` folder is optional.
* the `match.d` folder is mandatory.

Filenames inside `match.d` and `ignore.d`  must begin with a number of digits
followed by a minus and identifier and two more minus. Followed by an optional
category name. e.g. 00-header-private. The identifier with '-did-change'
appended is used as the name of the corresonding callback executable.
The executable must be located in "${MULLE_MONITOR_DIR}/bin".

The executable will be called with the following arguments and environment

Number | Argument | Description
-------|----------|---------------------------
 $1    | filepath | The file that has changed
 $2    | action   | One of three possible strings: "create" "modify" "update"
 $3    | category | The optional category of the matching file

Some environment variables will be available:

Variable                        | Description
--------------------------------|----------------------------
PWD                             | This variable and the working directory will be the monitored folder
MULLE_MONITOR_DIR               | Location of the `.mulle-monitor` folder
MULLE_MONITOR_LIBEXEC_DIR       | libexec directory of mulle-monitor
MULLE_BASHFUNCTIONS_LIBEXEC_DIR | libexec directory of mulle-bashfunctions


### mulle-monitor match

To test your ignore.d and match.d folders, you can use `mulle-monitor match`
to see if files match as expected.

```
mulle-monitor match src/foo.c
```

### mulle-monitor find

This is a facility to retrieve all matching filenames that match the filter
rules. You can decide which filter should be active and which not, by supplying
another filter, to filter the filters.

This example lists all the files, that pass through  "???-source--???" filters:

```
mulle-monitor find --match-filter "source"
```

