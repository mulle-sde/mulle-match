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
   ${MULLE_EXECUTABLE_NAME} task [options] <command>

   Manage tasks. A task is a plugin that is loaded by the monitor and executed
   on behalf of a callback. A callback may print a taskname to stdout. This is
   then used by the monitor to run the task.

   The reason for separating tasks and callbacks
   are:
      callbacks can be written in any language
      callbacks are one shot and keep no state
      tasks must be written in bash
      tasks can keep state in the running monitor, this is useful for job
      control.

Options:
   -h        : this help

Commands:
   install   : install
   list      : list installed tasks
   uninstall : uninstall
   require   : load task and check that the required main function is present
   run       : run task
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


require_task_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} require run <task>

   Load a task and check that the requirements are meant. This means that
   the task must provide an entry function called <task>_task_main.
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
      log_error "\"${_plugin}\" not found"
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


list_task_main()
{
   log_entry "list_task_main" "$@"

   [ "$#" -ne 0 ] && list_task_usage

   log_info "Tasks"
   if [ -d "${MULLE_MONITOR_DIR}/libexec" ]
   then
   (
      cd "${MULLE_MONITOR_DIR}/libexec"
      ls -1 *-task.sh 2> /dev/null | sed -e 's/-task\.sh//'
   )
   fi
}


require_task_main()
{
   log_entry "require_task_main" "$@"

   _cheap_help_options "require_task_usage"

   [ "$#" -lt 1 ] && require_task_usage

   local task="$1"

   local functionname

   functionname="task_${task}_main"
   if [ "`type -t "${functionname}"`" != "function" ]
   then
      _load_task "${task}" "${functionname}"
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


run_task_main()
{
   log_entry "run_task_main" "$@"

   _cheap_help_options "run_task_usage"

   [ "$#" -lt 1 ] && run_task_usage

   local task="$1"; shift

   local functionname

   require_task_main "${task}" || exit 1

   functionname="task_${task}_main"
   exekutor "${functionname}" "$@"
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
      list|locate|require|run|install|uninstall)
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
