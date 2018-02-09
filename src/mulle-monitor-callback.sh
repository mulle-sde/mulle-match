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
MULLE_MONITOR_CALLBACK_SH="included"


monitor_callback_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} callback [options] <command> <type> ...

   Locate or execute a callback with the given pattern type.

   Sometimes useful for testing mulle-monitor extensions.

Options:
   -h        : this help

Commands:
   install   : install <name> <filename>
   locate    : locate the callback for the given pattern type
   uninstall : uninstall <name> <filename>
   run       : run callback for the given pattern type
EOF
   exit 1
}


_locate_callback()
{
   log_entry "_locate_callback" "$@"

   local callback="$1"

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "MULLE_MONITOR_DIR not set"

   _executable="${MULLE_MONITOR_DIR}/bin/${callback}-callback"
   if [ -x "${_executable}" ]
   then
      return 0
   fi

   if [ -f "${_executable}" ]
   then
      log_error "\"${_executable}\" is not executable"
      return 1
   fi

   log_error "\"${_executable}\" not found"
   return 1
}


run_callback()
{
   log_entry "run_callback" "$@"

   local callback="$1"; shift

   local _executable

   if ! _locate_callback "${callback}"
   then
      return 1
   fi

   exekutor "${_executable}" "$@"
}


install_callback()
{
   log_entry "install_callback" "$@"

   local callback="$1"
   local filename="$2"

   [ -z "${filename}" ] && monitor_task_usage "missing filename"
   [ -f "${filename}" ] || fail "\"${filename}\" not found"

   local _executable

   _callback_executable_filename "${callback}"

   [ -e "${_executable}" -a "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ] \
      || fail "\"${_executable}\" already exists. Use -f to clobber"

   local bindir

   bindir="`dirname -- "${_executable}"`"
   mkdir_if_missing "${bindir}"
   exekutor cp "${filename}" "${_executable}"
   exekutor chmod +x "${_executable}"
}


uninstall_callback()
{
   log_entry "uninstall_callback" "$@"

   local callback="$1"

   local _executable

   _callback_executable_filename "${callback}"

   if [ ! -e "${_executable}" ]
   then
      log_warning "\"${_executable}\" does not exist."
      return 0
   fi

   remove_file_if_present "${_executable}"
}



###
###  MAIN
###
monitor_callback_main()
{
   log_entry "monitor_callback_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            monitor_callback_usage
         ;;

         -*)
            monitor_callback_usage "unknown option \"$1\""
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

   [ -z "${name}" ] && monitor_callback_usage "missing name"

   case "${cmd}" in
      run)
         [ $# -ne 0 ] && monitor_callback_usage "superflous arguments \"$*\""

         run_callback "${name}" "$@"
      ;;

      install|uninstall)
         local filename="$1"

         [ $# -ne 0 ] && monitor_callback_usage "superflous arguments \"$*\""

         ${cmd}_callback "${task}" "${filename}"
      ;;

      locate)
         [ $# -ne 0 ] && monitor_callback_usage "superflous arguments \"$*\""

         local _executable

         if ! _locate_callback "${name}"
         then
            return 1
         fi
         echo "${_executable}"
      ;;

      *)
         monitor_callback_usage "unknown command \"${cmd}\""
      ;;
   esac
}
