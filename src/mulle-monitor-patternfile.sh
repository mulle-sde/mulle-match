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
MULLE_MONITOR_PATTERN_FILE_SH="included"


monitor_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} patternfile [options] <command>

   Operations on patternfiles. Currently it can only read existing
   patternfiles.

   Place ignore patternfiles into \"${MULLE_MONITOR_ETC_DIR}/share/ignore.d\".
   Place match patternfiles into \"${MULLE_MONITOR_ETC_DIR}/share/match.d\".

Options:
   -h         : this help
   -i         : use ignore.d instead of match.d

Commands:
   list       : list patternfiles
   get <file> : show contents of patternfile
EOF
   exit 1
}


monitor_patternfile_list_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} patternfile list [options]

   List patternfiles

Options:
   -h         : this help
   -p         : print patternfile contents
EOF
   exit 1
}


_list_patternfiles()
{
   log_entry "_list_patternfiles" "$@"

   local folder="$1"

   if [ -d "${folder}" ]
   then
   (
      exekutor cd "${folder}"
      exekutor ls -1 | egrep '[0-9]*-.*--.*'
   )
   fi
}


list_patternfiles()
{
   log_entry "list_patternfiles" "$@"

   local OPTION_DUMP="NO"

   while :
   do
      case "$1" in
         -h|--help)
            monitor_patternfile_list_usage
         ;;

         -p|--print-contents)
            OPTION_DUMP="YES"
         ;;

         -*)
            monitor_patternfile_list_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local folder

   folder="${MULLE_MONITOR_MATCH_DIR}"
   case "${FOLDER_NAME}" in
      ignore.d)
         folder=""${MULLE_MONITOR_IGNORE_DIR}""
      ;;
   esac

   if [ "${OPTION_DUMP}" != "YES" ]
   then
      _list_patternfiles "${folder}"
      return $?
   fi

   local patternfile

   IFS="
"
   for patternfile in `_list_patternfiles "${folder}"`
   do
      IFS="${DEFAULT_IFS}"
      log_info "-----------------------------------------"
      log_info "${FOLDER_NAME}/${patternfile}"
      log_info "-----------------------------------------"
      cat "${folder}/${patternfile}"
      echo

   done
   IFS="${DEFAULT_IFS}"
}


get_patternfile()
{
   log_entry "get_patternfile" "$@"

   local filename="$1"

   case "${FOLDER_NAME}" in
      ignore.d)
         cat "${MULLE_MONITOR_IGNORE_DIR}/${filename}"
      ;;

      *)
         cat "${MULLE_MONITOR_MATCH_DIR}/${filename}"
      ;;
   esac
}


#
# TODO: check that we are not accidentally overwriting share
#       if there is a share but no etc setup a new etc and
#       copy share stuff over.
#
set_patternfile()
{
   fail "Not yet implemented"
}

###
###  MAIN
###
monitor_patternfile_main()
{
   log_entry "monitor_patternfile_main" "$@"

   local FOLDER_NAME="match.d"
   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            monitor_patternfile_usage
         ;;

         -i)
            FOLDER_NAME="ignore.d"
         ;;

         -*)
            monitor_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"
   [ $# -ne 0 ] && shift

   case "${cmd}" in
      list)
         list_patternfiles "$@"
      ;;

      get)
         filename="$1"
         [ $# -ne 0 ] && shift
         [ -z "${filename}" ] && monitor_patternfile_usage "missing filename argument"
         [ $# -ne 0 ] && monitor_patternfile_usage "superflous arguments \"$*\""

         get_patternfile "${filename}"
      ;;

      *)
         monitor_patternfile_usage "unknown command \"${cmd}\""
      ;;
   esac
}
