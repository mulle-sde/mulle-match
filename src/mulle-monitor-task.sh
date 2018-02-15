#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_MONITOR_TASK_SH="included"


monitor_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task <command>

   Manage tasks. A task is a plugin that is loaded by the monitor and executed
   on behalf of a callback. A callback may print a taskname to stdout. This is
   then used by the monitor to run the task.

Commands:
   install   : install a bash script as a task
   kill      : kill a running task
   list      : list installed tasks
   ps        : list running tasks
   uninstall : uninstall a task
   test      : load task and check that the required main function is present
   run       : run task
   status    : get status of running or last ran task
EOF
   exit 1
}


install_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task install <task> <script>

   Install a sourceable bash script as a mulle-sde task. You may specify '-' as
   to read it from stdin.
EOF
   exit 1
}


uninstall_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task uninstall <task>

   Remove a task.
EOF
   exit 1
}


list_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task list

   List installed tasks.
EOF
   exit 1
}


test_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task test <task>

   Load a task and check that the task provides an entry function called
   <task>_task_run.
EOF
   exit 1
}


ps_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task ps

   List running tasks and their pids.
EOF
   exit 1
}


kill_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task kill <task>

   Kill a running task.
EOF
   exit 1
}


status_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task status <task>

   Check status of a task. These are the returned values:

   done    : task successfully
   failed  : task completed with errors
   running : still running
   unknown : possibly never ran yet

EOF
   exit 1
}


run_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} task run <task> ...

   Run a task. Depending on the task, you may be able to pass additional
   arguments to the task.
EOF
   exit 1
}


_cheap_help_options()
{
   local usage="$1"

   while :
   do
      case "$1" in
         -h|--help)
            "${usage}"
         ;;

         -*)
             "${usage}" "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done
}


_task_donefile()
{
   log_entry "_task_donefile" "$@"

   local task="$1"

   echo "${MULLE_MONITOR_DIR}/var/run/monitor/${task}-task"
}


_task_pidfile()
{
   log_entry "_task_pidfile" "$@"

   local task="$1"

   echo "${MULLE_MONITOR_DIR}/var/run/monitor/${task}-task.pid"

}

_task_main_function()
{
   log_entry "_task_main_function" "$@"

   local task="$1"

   local taskidentifier

   taskidentifier="`tr -c '[a-zA-Z0-9_\n]' '_' <<< "${task}"`"

   echo "${taskidentifier}_task_run"
}


_task_plugin_filename()
{
   log_entry "_task_plugin_filename" "$@"

   local task="$1"

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "MULLE_MONITOR_DIR not set"

   _plugin="${MULLE_MONITOR_DIR}/libexec/${task}-task.sh"
}


_locate_task()
{
   log_entry "_locate_task" "$@"

   _task_plugin_filename "$@"

   if [ ! -f "${_plugin}" ]
   then
      log_error "There is no installed task \"$1\"."
      return 1
   fi
}


_load_task()
{
   log_entry "_load_task" "$@"

   local task="$1"
   local functionname="$2"

   local _plugin

   if ! _locate_task "${task}"
   then
      exit 1
   fi

   . "${_plugin}" || exit 1

   if [ "`type -t "${functionname}"`" != "function" ]
   then
      fail "\"${_plugin}\" does not define function \"${functionname}\""
   fi
}


_require_task()
{
   log_entry "_require_task" "$@"

   local task="$1"

   local functionname

   functionname="`_task_main_function "${task}"`"
   if [ "`type -t "${functionname}"`" != "function" ]
   then
      _load_task "${task}" "${functionname}"
   fi
}


remove_task_job()
{
   log_entry "add_task_job" "$@"

   local task="$1"

   local taskpidfile

   taskpidfile="`_task_pidfile "${task}"`"
   kill_pid "${taskpidfile}"
}


remember_task_rval()
{
   log_entry "remember_task_rval" "$@"

   local task="$1"
   local rval="$2"

   local taskdonefile
   local status

   status="failed"
   case "${rval}" in
      0)
         status="done"
      ;;

      "")
         internal_fail "rval is empty"
      ;;
   esac

   taskdonefile="`_task_donefile "${task}"`"
   mkdir_if_missing "`fast_dirname "${taskdonefile}"`"
   redirect_exekutor "${taskdonefile}" echo "${status}"
}


add_task_job()
{
   log_entry "add_task_job" "$@"

   local task="$1" ; shift
   local taskdelay="$1" ; shift
   # rest commandline

   local taskpidfile

   taskpidfile="`_task_pidfile "${task}"`"
   kill_pid "${taskpidfile}"

   local timestamp

   timestamp="`date +"%s"`"
   timestamp="`expr $timestamp + ${taskdelay}`"

   case "${MULLE_UNAME}" in
      darwin)
         log_fluff "==> Scheduled task \"${task}\" for" `date -r ${timestamp} "+%H:%M:%S"`
      ;;
   esac

   (
      trap 'log_fluff "Task \"${task}\" with pid ${BASHPID} killed" ; exit 1' TERM

      announce_current_pid "${taskpidfile}"
      sleep "${taskdelay}"

      log_fluff "==> Starting task"

      eval_exekutor "$@"
      remember_task_rval "${task}" "$?"

      log_fluff "==> Ended task"

      done_pid "${taskpidfile}"
   ) &
}


run_task_job()
{
   log_entry "run_task_job" "$@"

   local task="$1"; shift

   local functionname

   _require_task "${task}" || exit 1
   functionname="`_task_main_function "${task}"`"

   #
   # check that a task of same name is not running/schedulded. If yes
   # prempt it.
   #
   # Delay task schedule by 1 second, so that we can "coalesce"
   # incoming events
   #
   add_task_job "${task}" "1" "'${functionname}'" "$@"
}


run_task_main()
{
   log_entry "run_task_main" "$@"

   local task="$1"; shift

   local functionname
   local taskidentifier

   taskidentifier="`tr -c '[a-zA-Z0-9_\n]' '_' <<< "${task}"`"

   _require_task "${task}" || exit 1
   functionname="`_task_main_function "${task}"`"

   local taskpidfile

   taskpidfile="`_task_pidfile "${task}"`"
   kill_pid "${taskpidfile}"

   announce_current_pid "${taskpidfile}"
   exekutor "${functionname}" "$@"
   remember_task_rval "${task}" "$?"

   done_pid "${taskpidfile}"
}


install_task_main()
{
   log_entry "install_task_main" "$@"

   _cheap_help_options "install_task_usage"

   [ "$#" -ne 2 ] && install_task_usage

   local task="$1"
   local filename="$2"

   [ -z "${filename}" ] && install_task_usage "missing filename"
   [ "${filename}" = "-" -o -f "${filename}" ] || fail "\"${filename}\" not found"

   local _plugin

   _task_plugin_filename "${task}"

   [ -e "${_plugin}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = "NO" ] \
      && fail "\"${_plugin}\" already exists. Use -f to clobber"

   local plugindir

   plugindir="`dirname -- "${_plugin}"`"

   patternfile="${OPTION_POSITION}-${typename}--${OPTION_CATEGORY}"
   if [ "${filename}" = "-" ]
   then
      local text

      text="`cat`"
      mkdir_if_missing "${plugindir}" # do as late as possible
      redirect_exekutor "${_plugin}" echo "${text}"
   else
      mkdir_if_missing "${plugindir}"
      exekutor cp "${filename}" "${_plugin}"
   fi
   exekutor chmod -x "${_plugin}"
}


uninstall_task_main()
{
   log_entry "uninstall_task_main" "$@"


   _cheap_help_options "uninstall_task_usage"

   [ "$#" -ne 1 ] && uninstall_task_usage

   local task="$1"

   local _plugin

   _task_plugin_filename "${task}"

   if [ ! -e "${_plugin}" ]
   then
      log_warning "\"${_plugin}\" does not exist."
      return 0
   fi

   remove_file_if_present "${_plugin}"
}


list_task_main()
{
   log_entry "list_task_main" "$@"

   [ "$#" -ne 0 ] && list_task_usage

   log_info "Tasks:"
   if [ -d "${MULLE_MONITOR_DIR}/libexec" ]
   then
   (
      cd "${MULLE_MONITOR_DIR}/libexec"
      ls -1 *-task.sh 2> /dev/null | sed -e 's/-task\.sh//'
   )
   fi
}


test_task_main()
{
   log_entry "test_task_main" "$@"

   _cheap_help_options "test_task_usage"

   [ "$#" -lt 1 ] && test_task_usage

   _require_task "$@"
}


status_task_main()
{
   log_entry "status_task_main" "$@"

   _cheap_help_options "status_task_usage"

   [ "$#" -lt 1 ] && status_task_usage

   local task="$1"

   local taskpidfile
   local taskdonefile

   taskpidfile="`_task_pidfile "${task}"`"
   if [ -f "${taskpidfile}" ]
   then
      echo "running"
      return
   fi

   taskdonefile="`_task_donefile "${task}"`"
   if [ -f "${taskdonefile}" ]
   then
      cat "${taskdonefile}"
      return
   fi

   echo "unknown"
}


kill_task_main()
{
   log_entry "status_task_main" "$@"

   _cheap_help_options "kill_task_usage"

   [ "$#" -lt 1 ] && kill_task_usage

   local task="$1"

   local taskdonefile

   taskpidfile="`_task_pidfile "${task}"`"
   if [ ! -f "${taskpidfile}" ]
   then
      log_warning "Task \"${task}\" not known to be running. \
Started by a different monitor ?"
      return 1
   fi

   local pid

   pid="`cat "${taskpidfile}"`"
   if [ "${pid}" != "$$" ]
   then
      log_fluff "Killing \"${task}\" with pid $pid"
      kill $pid
   else
      log_warning "Task \"${task}\" is running synchronous, can't kill"
   fi
}


ps_task_main()
{
   log_entry "ps_task_main" "$@"

   [ "$#" -ne 0 ] && list_task_usage

   log_info "Running Tasks:"
   if [ -d "${MULLE_MONITOR_DIR}/var/run/monitor" ]
   then
   (
      cd "${MULLE_MONITOR_DIR}/var/run/monitor"
      IFS="
"
      for pidfile in `ls -1 *-task.pid 2> /dev/null`
      do
         task="`sed -e 's/-task\.pid//' <<< "${pidfile}"`"
         pid="`cat "${pidfile}"`"
         if [ "${pid}" = "$$" ]
         then
            pid=""
         fi
         echo "$pid" "${task}"
      done
   )
   fi
}


# "Hidden" command for testing
locate_task_main()
{
   log_entry "locate_task_main" "$@"

   _cheap_help_options "run_task_usage"

   [ "$#" -lt 1 ] && run_task_usage

   local task="$1"; shift

   local _plugin

   _locate_task "${task}" || exit 1

   exekutor echo "${_plugin}"
}



###
###  MAIN
###
monitor_task_main()
{
   log_entry "monitor_task_main" "$@"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || exit 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-file.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || exit 1
   fi

   if [ -z "${MULLE_MONITOR_PROCESS_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-process.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-process.sh" || exit 1
   fi

   _cheap_help_options "monitor_task_usage"


   local cmd="$1"
   [ $# -ne 0 ] && shift

   case "${cmd}" in
      install|kill|list|locate|ps|run|status|test|uninstall)
         ${cmd}_task_main "$@"
      ;;

      "")
         monitor_task_usage
      ;;

      *)
         monitor_task_usage "unknown command \"${cmd}\""
      ;;
   esac
}
