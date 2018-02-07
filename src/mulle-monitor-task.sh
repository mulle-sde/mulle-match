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
   ${MULLE_EXECUTABLE_NAME} task [options] <command> <name> ...

   Execute a task with the given name. Sometimes useful for testing
   mulle-monitor extensions.

Options:
   -h  : this help

Commands:
   locate  : locate task plugin of given name
   require : load task and check if required main function is present
   run     : run task of given name
EOF
   exit 1
}


_locate_task()
{
   log_entry "_locate_callback" "$@"

   local task="$1"

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "MULLE_MONITOR_DIR not set"

   _plugin="${MULLE_MONITOR_DIR}/libexec/${task}-task.sh"
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


require_task()
{
   log_entry "require_task" "$@"

   local task="$1"

   local functionname

   functionname="task_${task}_main"
   if [ "`type -t "${functionname}"`" != "function" ]
   then
      _load_task "${task}" "${functionname}"
   fi
}


run_task()
{
   log_entry "run_task" "$@"

   local task="$1"; shift

   local functionname

   require_task "${task}" || exit 1

   functionname="task_${task}_main"
   "${functionname}" "$@"
}


###
###  MAIN
###
monitor_task_main()
{
   log_entry "monitor_task_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            monitor_task_usage
         ;;

         -*)
            monitor_task_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   if [ -z "${MULLE_MONITOR_PROCESS_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-process.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-process.sh" || exit 1
   fi

   local cmd="$1"
   [ $# -ne 0 ] && shift

   local name="$1"
   [ $# -ne 0 ] && shift

   [ -z "${name}" ] && monitor_task_usage "missing name"

   case "${cmd}" in
      run)
         run_task "${name}" "$@"
      ;;

      require)
         require_task "${name}"
      ;;

      locate)
         local _plugin

         if ! _locate_task "${name}"
         then
            return 1
         fi
         echo "${_plugin}"
      ;;

      *)
         monitor_task_usage "unknown command \"${cmd}\""
      ;;
   esac
}
