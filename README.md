 🕵🏻‍ Extensible filesystem observation

... for Linux, OS X, FreeBSD, Windows

![](mulle-monitor.png)

**mulle-monitor** watches changes in a folder (and subfolders) using
[fswatch](https://github.com/emcrisostomo/fswatch) or
[inotifywait](https://linux.die.net/man/1/inotifywait). I then
matches the observed filename against a set of patterns and then calls 
the appropriate callback executables based on this pattern-match.
The callback then may trigger further tasks.

![](dox/mulle-monitor-overview.png)



Executable      | Description
----------------|--------------------------------
`mulle-monitor` | Observe changes in filesystem and react to them


## Matching

![](dox/mulle-monitor-match.png)

Matching is done on filenames.

Matching is done by matching the filename against all *patternfiles* in a 
folder. If a *patternfile* matches then the search has succeeded and the folder 
matches. Otherwise the search continues with the next *patternfile*.

Each *patternfile* is made up of one or more *patterns*. Each *pattern* is
a **bash pattern** and it is matched against the filename. This is quite 
like a `.gitignore` file.

The [Wiki](https://github.com/mulle-sde/mulle-monitor/wiki) explains this in 
much more detail.


## Commands

### mulle-monitor run

![](dox/mulle-monitor-run.png)

```
mulle-monitor run
```

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

In a bit more detail. `mulle-monitor run` observes the project folder using
`fswatch` or `inotifywait`. The incoming events are preprocessed and categorized
into three event types: "create" "update" "delete". An event that doesn't fit
these three event types is ignored.

Then the event's filename is classified using **matching**
(see above). The result of this classification is the name of the "-callback"
callback. In the picture the matching returned `source-callback`,
so a matching rule of the form "nnn-source--xxx" must have matched.

The callback will now be executed. It gets the event type and the filename and
the category of the matching rule as arguments. The callback may produce
a task identifier.

If a task identifier is produced, this is used to load a plugin (in the
picture case `build-task.sh`). A main function of this plugin is then
executed.

> Note: Due to  caching of patternfiles, you need
> to restart `mulle-monitor run` to pick up edits to a *patternfile*.


### mulle-monitor match

To test your ignore.d and match.d folders, you can use `mulle-monitor match` to
see if files match as expected.

```
mulle-monitor match src/foo.c
```

You can also test individual *patterns* using the `--pattern` option: 

```
mulle-monitor match --pattern '*.c' src/foo.c
```

### mulle-monitor find

This is a facility to retrieve all filenames that match. You can decide which 
*patternfile* should be active and which not, by supplying a filter to filter 
by *patternfile* types.

This example lists all the files, that pass through filters of type "source":

```
mulle-monitor find --match-filter "source"
```


### mulle-monitor callback

Manage callback executables.

```
mulle-monitor callback install source "my-script"
```


### mulle-monitor patternfile

Manage *patternfiles*.


List all `ignore.d` *patternfiles*:

```
mulle-monitor patternfile -i list
```


### mulle-monitor task

Manage task plugins.

```
mulle-monitor task install hello "my-plugin.sh"
```
