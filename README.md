 🕵🏻‍ Extensible filesystem observation

... for Linux, OS X, FreeBSD, Windows

**mulle-monitor** watches changes in a folder (and subfolders) using
[fswatch](https://github.com/emcrisostomo/fswatch) or
[inotifywait](https://linux.die.net/man/1/inotifywait) and then calls an
appropriate callback executables based on user supplied filter rules.
The callback then may trigger further tasks.

![](dox/mulle-monitor-overview.png)



Executable      | Description
----------------|--------------------------------
`mulle-monitor` | Observe changes in filesystem and react to them

## Matching

![](dox/mulle-monitor-match.png)

Matching is done on filenames. A filename should be fully resolved and it should not be absolute. It should not contain relative components like `.` `..`. **mulle-monitor** takes care of that and it shouldn't concern you too much.

A filename is matched like this:
 
#### 1. The proper `ignore.d` and `match.d` folders are determined.


1. A `etc/ignore.d` folder overrides the `share/ignore.d` folder.
2. The `etc/match.d` folder overrides the `share/match.d` folder.
3. An `ignore.d` folder is optional.
4. A `match.d` folder is mandatory.


#### 2. The filename is matched against the pattern files in the  `ignore.d` folder

The files in the folder are called *pattern files*. Each *pattern file* contains a sequence of *rules*. If the filename matches all *rules*, then *pattern file* is matched. In the case of `ignore.d`, this means that filename will be ignored and no further processing is needed.


#### 3. The filename is matched against the pattern files in the `match.d` folder

This is the same as how filename is matched against `ignore.d`. The obvious difference being, that
a matching *pattern file* now means a successful match.


### Pattern file - naming scheme

The filename of a *pattern file* must begin with a number of digits followed by a minus a *type* identifier and two more minus. After the two minus there may be an optional *category* identifier. 

> The digits are used for sorting. All files inside a folder should have the same 
> number of leading digits. Then the *pattern file*.


e.g. 00-header--private. 

digits|-|type  |--|category
------|-|------|--|--------
00    |-|header|--|private

>It is customary to use "all" as the category identifier, if no further 
> categorization is needed.


### Pattern file - rules

A pattern file is a sequence of rules. Each rule is on a line. Read how a [.gitignore](https://git-scm.com/docs/gitignore) file works, as that's pretty similar to the way a *pattern file* work.
The pattern matching is done using bash `case` regular expressions with a few extensions:

Pattern           | Description
------------------|------------------------
`expr/`      	  | Matches any file or folder matched by expr and it's recursive contents
`/expr`           | Matches expr only if it matches from the start
!<expr>           | Negate expression. It's not possible to negate a negated expression.


Here is a simple example to match `.txt` files that are stored somewhere inside
the doc folder or subfolders. But it avoids those, that are in an "old" folder.

```
mkdir .mulle-monitor/etc/match.d
cat <<EOF > .mulle-monitor/etc/match.d/00-doc-all
/doc/*.txt
!old/
EOF
```



## Commands

### mulle-monitor run

![](dox/mulle-monitor-run.png)

Start the monitor to observe changes in your project folder. If a
change passes the filters, the appropriate callback is executed.

The operation of `mulle-monitor run` in a very simplified form is comparable to:

```
for filename in ${observed_changed_filenames}
do
   did_change_script="`mulle-monitor match "${filename}"`"
   task_plugin_sh="`"${did_change_script}" "${filename}"`"
   . "${task_plugin_sh}"
done
``` 

In a bit more detail. mulle-monitor run observes the project folder using
fswatch or inotifywait. The incoming events are preprocessed and categorized
into three event types: "create" "update" "delete". An event that doesn't fit 
those types is ignored.

Then the changed filename is classified using the **matching** 
(see above). The result of this classification is the name of the "-did-change" 
callback. In the picture the matching returned `source-did-change`, 
so a matching rule of the form "nnn-source--xxx" must have matched.

The callback will now be executed. It gets the event type and the filename and 
the 'xxx' part of the matching rule as arguments. The callback may produce
a task identifier.

If a task identifier is produced, this is used to load a plugin (in the 
picture case `build-task.sh`). A main function of this plugin is then 
executed.

> Note: Due to  caching of pattern files, you need 
> to restart `mulle-monitor run` to pick up edits to a *pattern file*.

### mulle-monitor match


To test your ignore.d and match.d folders, you can use `mulle-monitor match` to 
see if files match as expected.

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


## Callback

To the **type** identifier the string '-did-change' is appended to form the 
name of the  callback executable. This executable must be located in 
`${MULLE_MONITOR_DIR}/bin`.

The executable will be called with the following arguments and environment

Number | Argument | Description
-------|----------|---------------------------
 $1    | filepath | The file that has changed
 $2    | action   | One of three possible strings: "create" "modify" "update"
 $3    | category | The optional category of the matching file

Some environment variables will be available:

Variable                          | Description
----------------------------------|----------------------------
`PWD`                             | This variable and the working directory will be the project folder
`MULLE_MONITOR_DIR`               | Location of the `.mulle-monitor` folder
`MULLE_MONITOR_ETC_DIR`           | Location of the `etc` folder
`MULLE_MONITOR_MATCH_DIR`         | Location of the `match.d` folder
`MULLE_MONITOR_IGNORE_DIR`        | Location of the `ignore.d` folder
`MULLE_MONITOR_LIBEXEC_DIR`       | libexec directory of mulle-monitor
`MULLE_BASHFUNCTIONS_LIBEXEC_DIR` | libexec directory of mulle-bashfunctions

