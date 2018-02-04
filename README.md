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

* the `ignore` folder is optional
* the `match` folder is mandatory

`match` and `ignore`  filenames must begin with a number of digits followed by 
an underscore. e.g. 00_source. The rest of the filename is used to locate the 
corresonding callback function, with '-did-change' appended. The executable 
must be located in "${MULLE_MONITOR_DIR}/bin".

The executable will be called with the following arguments and environment

Number | Argument | Description
-------|----------|---------------------------
 $1    | filepath | The file that has changed
 $2    | action   | One of three possible strings: "create" "modify" "update"

Some environment variables will be available:

Variable                        | Description
--------------------------------|----------------------------
PWD                             | This variable and the working directory will be the monitored folder
MULLE_MONITOR_DIR               | Location of the `.mulle-monitor` folder 
MULLE_MONITOR_LIBEXEC_DIR       | libexec directory of mulle-monitor
MULLE_BASHFUNCTIONS_LIBEXEC_DIR | libexec directory of mulle-bashfunctions
