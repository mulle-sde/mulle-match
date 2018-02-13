 🕵🏻‍ Extensible filesystem observation

... for Linux, OS X, FreeBSD, Windows

![](mulle-monitor.png)

**mulle-monitor** watches for changes in a folder (and subfolders) using
[fswatch](https://github.com/emcrisostomo/fswatch) or
[inotifywait](https://linux.die.net/man/1/inotifywait). It then
matches the observed filename against a set of *patternfiles* and then calls
the appropriate callback executable based on this pattern matching.
The callback then may trigger further tasks.

![](dox/mulle-monitor-overview.png)


Executable      | Description
----------------|--------------------------------
`mulle-monitor` | Observe changes in filesystem and react to them


## Matching

Matching is done against filenames only.

Matching is done by matching the filename against all *patternfiles* in two
special *match folders* `ignore.d` and `match.d`. 

If a *patternfile* of the `ignore.d` folder matches, the matching has failed. 
On the other hand, if a *patternfile* of `match.d` marches, the 
matching has succeeded. *patternfiles* are matched in sort order.

![](dox/mulle-monitor-match.png)

> * the *patternfiles* are green
> * the *match-folder*s are `ignore.d` and `match.d`
> * the blue uppercase boxes represent environment variables


Each *patternfile* is made up of one or more *patterns*. 

Example:

```
# match .c .h and .cpp files
*.c
*.h
*.cpp

# ignore backup files though
!*~.*
```

This is quite like a `.gitignore` file, with the same semantics for negation. The matching is a bit less sophisticated though, since * matches everything.

> The [Wiki](https://github.com/mulle-sde/mulle-monitor/wiki) 
> explains this in much more detail.


## Commands

### mulle-monitor run


```
mulle-monitor -e run
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

#### In a bit more detail. 

`mulle-monitor run` observes the project folder using
`fswatch` or `inotifywait`. These generate events, whenever the filesystem changes.

![](dox/mulle-monitor-run.png)

The incoming events are categorized
into three event types: **create**, **update**, **delete**. An event that doesn't fit these three event types is ignored.

Then the event's filename is classified using **matching**
(see above). The result of this classification is the name of the *callback*. 

The *callback* will now be executed. As its arguments it gets the event type (e.g. **updated**), the filename, and the category of the matching rule. 

The callback may produce a task name, by echoing it to stdout. If a task name is produced, then the this task is executed. 

> The [Wiki](https://github.com/mulle-sde/mulle-monitor/wiki) 
> explains this also in much more detail.


### mulle-monitor match

To test your *patternfiles* you can use `mulle-monitor match`. It will output the *callback* name if a file matches.

```
mulle-monitor -e match pix/foo.png
```

You can also test individual *patterns* using the `--pattern` option:

```
mulle-monitor -e match --pattern '*.png' pix/foo.png
```


### mulle-monitor find

This is a facility to retrieve all filenames that match *patternfiles*. You can decide which
*patternfile* should be used by supplying a filter.

This example lists all the files, that pass through *patternfiles* of type "hello":

```
mulle-monitor -e find --match-filter "hello"
```


### mulle-monitor callback

Manage *callbacks*.

Add a python *callback* for "hello":

```
cat <<EOF > my-callback.py
#!/usr/bin/env python
print "world"
EOF
mulle-monitor -e callback install hello my-callback.py
```

Remove a *callback*

```
mulle-monitor -e callback uninstall hello
```

List all *callback*:

```
mulle-monitor -e callback list
```


### mulle-monitor patternfile

Manage *patternfiles*.


Add a *patternfile* to select the *callback* "hello":

```
echo "*.png" > pattern.txt
mulle-monitor -e patternfile install hello pattern.txt
```

Remove a *patternfile*

```
mulle-monitor -e patternfile uninstall hello
```

List all *patternfiles*:

```
mulle-monitor -e patternfile list
```

> Note: Due to  caching of patternfiles, you need
> to restart `mulle-monitor run` to pick up edits to a *patternfile*.

### mulle-monitor task

Manage *task* plugins.

Add a sourcable shell script as a *task*. It needs to define the function `task_world_main` to be a usable plugin for the task "world":

```
cat <<EOF > my-plugin.sh
task_world_main()
{
   echo "VfL Bochum 1848"
}
EOF
mulle-monitor -e task install world "my-plugin.sh"
```

Remove a *task* named "world"

```
mulle-monitor -e task uninstall world 
```


List all *tasks*:

```
mulle-monitor -e task list
```
