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

   A callback is executed, when there has been an interesting change in the
   filesystem. These changes are categorized by "patternfile"s and
   are used to determine the callback to execute.
   A callback may return string, which will be interpreted as a "task" to
   perform. See \`${MULLE_EXECUTABLE_NAME} task help\` and
   \`${MULLE_EXECUTABLE_NAME} patternfile help\` for more information.

Options:
   -h        : this help

Commands:
   install   : install a callback
   list      : list installed callbacks
   uninstall : uninstall a callback
   run       : run a callback
EOF
   exit 1
}


install_callback_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} callback install [options] <callback> <executable>

   Install an executable as a mulle-sde callback.

Options:
   -h        : this help
EOF
   exit 1
}


uninstall_callback_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} callback uninstall [options] <callback>

   Remove callback.

Options:
   -h        : this help
EOF
   exit 1
}


list_callback_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} callback list

   List installed callbacks.

Options:
   -h        : this help
EOF
   exit 1
}


run_callback_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} callback run <callback> ...

   Run a callback with any number of arguments.

Options:
   -h        : this help
EOF
   exit 1
}


_callback_executable_filename()
{
   log_entry "_callback_executable_filename" "$@"

   local callback="$1"

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "MULLE_MONITOR_DIR not set"

   _executable="${MULLE_MONITOR_DIR}/bin/${callback}-callback"
   [ -x "${_executable}" ]
}


_locate_callback()
{
   log_entry "_locate_callback" "$@"

   local callback="$1"

   [ -z "${MULLE_MONITOR_DIR}" ] && internal_fail "MULLE_MONITOR_DIR not set"

   if _callback_executable_filename "${callback}"
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


uninstall_callback_main()
{
   log_entry "uninstall_callback_main" "$@"

   _cheap_help_options "uninstall_callback_usage"

   [ "$#" -ne 1 ] && uninstall_callback_usage

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


install_callback_main()
{
   log_entry "install_callback_main" "$@"

   _cheap_help_options "install_callback_usage"

   [ "$#" -ne 2 ] && install_callback_usage

   local callback="$1"
   local filename="$2"

   [ -z "${filename}" ] && monitor_task_usage "missing filename"
   [ "${filename}" = "-" -o -f "${filename}" ] || fail "\"${filename}\" not found"

   local _executable

   _callback_executable_filename "${callback}"

   [ -e "${_executable}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = "NO" ] \
      && fail "\"${_executable}\" already exists. Use -f to clobber"

   local bindir

   bindir="`fast_dirname "${_executable}"`"
   if [ "${filename}" = "-" ]
   then
      local text

      text="`cat`"
      mkdir_if_missing "${bindir}" # do as late as possible
      redirect_exekutor "${_executable}" echo "${text}"
   else
      mkdir_if_missing "${bindir}"
      exekutor cp "${filename}" "${_executable}"
   fi
   exekutor chmod +x "${_executable}"
}


# "hidden" function used for testing

locate_callback_main()
{
   log_entry "locate_callback_main" "$@"

   _cheap_help_options "run_callback_usage"

   [ "$#" -lt 1 ] && run_callback_usage

   local callback="$1"; shift

   local _executable

   if ! _locate_callback "${callback}"
   then
      return 1
   fi

   exekutor echo "${_executable}"
}


run_callback_main()
{
   log_entry "run_callback_main" "$@"

   _cheap_help_options "run_callback_usage"

   [ "$#" -lt 1 ] && run_callback_usage

   local callback="$1"; shift

   [ -z "${callback}" ] && internal_fail "empty callback"

   local _executable

   if ! _locate_callback "${callback}"
   then
      return 1
   fi

   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" \
      exekutor "${_executable}" "$@"
}


list_callback_main()
{
   log_entry "list_callback_main" "$@"

   _cheap_help_options "list_callback_usage"

   [ "$#" -ne 0 ] && list_callback_usage

   log_info "Callbacks:"
   if [ -d "${MULLE_MONITOR_DIR}/bin" ]
   then
   (
      cd "${MULLE_MONITOR_DIR}/bin"
      ls -1 *-callback 2> /dev/null | sed -e 's/-callback$//'
   )
   fi
}



###
###  MAIN
###
monitor_callback_main()
{
   log_entry "monitor_callback_main" "$@"

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

   #
   # handle options
   #
   _cheap_help_options "monitor_callback_usage"

   local cmd="$1"
   [ $# -ne 0 ] && shift

   case "${cmd}" in
      list|locate|run|install|uninstall)
         ${cmd}_callback_main "$@"
      ;;

      "")
         monitor_callback_usage
      ;;

      *)
         monitor_callback_usage "unknown command \"${cmd}\""
      ;;
   esac
}
