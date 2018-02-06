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
   ${MULLE_EXECUTABLE_NAME} task [options] <name> [filepath]

   Execute a task with the given name.
   Sometimes useful for testing mulle-monitor extensions.

   Builtin tasks are: craft and test.

Options:
   -h  : this help
EOF
   exit 1
}


run_task()
{
   log_entry "run_task" "$@"

   local task="$1"
   local filepath="$2"

   #
   # grab task prefrably from project libexecdir. If there is no such
   # file, use builtin
   #
   functionname="${task}_task_main"
   if [ "`type -t "${functionname}"`" != "function" ]
   then
      libexecname="${task}-task.sh"
      libexecfile="${MULLE_MONITOR_DIR}/libexec/${libexecname}"

      if [ -x "${libexecfile}" ]
      then
         . "${libexecfile}" || exit 1
      else
         libexecfile="${MULLE_MONITOR_LIBEXEC_DIR}/tasks/${libexecname}"
         . "${libexecfile}" || fail "missing \"${libexecname}\" script"
      fi

      if [ "`type -t "${functionname}"`" != "function" ]
      then
         fail "\"${libexecfile}\" does not define function \"${functionname}\""
      fi
   fi

   "${functionname}" "${filepath}"
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

   [ "$#" -lt 1 -o "$#" -gt 2 ] && monitor_task_usage "wrong number of arguments \"$*\""

   if [ -z "${MULLE_MONITOR_PROCESS_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-process.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-process.sh" || exit 1
   fi

   run_task "$@"
}
