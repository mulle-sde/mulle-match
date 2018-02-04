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
MULLE_MONITOR_MATCH_SH="included"


monitor_match_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} match [options] <filename>+

   Run the mulle-monitor file classification with the given filenames.
   It will emit the contentype being matched, if there is any.

Options:
   -d <dir>       : project directory (parent of .mulle-monitor)
   -f <format>    : specify output values. This is like a simplified C
                    printf format:
                        %c : contentype
                        %m : full matching filename
                        %f : filename being matched
                        %n : filename without leading folders
                        \\n : a linefeed
EOF
   exit 1
}



#
# This is pretty similiar to.gitignore. For most purposes it should
# be identical. It doesn't work with
#
pattern_matches_relative_filename()
{
   log_entry "pattern_matches_relative_filename" "$@"

   local pattern="$1"
   local text="$2"
   local flags="$3"

   #
   # if we are strict on text input, we can simplify pattern handling
   # a lot. Note that we only deal with relative paths anyway
   #
   case "${text}" in
      "")
         internal_fail "Empty text is illegal"
      ;;

      /*)
         internal_fail "Text \"${text}\" is illegal. It must not start with '/'"
      ;;

      */)
         internal_fail "Text \"${text}\" is illegal. It must not end with '/'"
      ;;
   esac

   case "${pattern}" in
      "")
         internal_fail "Empty pattern is illegal"
      ;;

      *//*)
         internal_fail "Pattern \"${pattern}\" is illegal. It must not contain  \"//\""
      ;;
   esac

   local YES=0
   local NO=1

   # gratuitous

   case "${flags}" in
      *WM_CASEFOLD*)
         pattern="` tr 'A-Z' 'a-z' <<< "${pattern}" `"
      ;;
   esac

   #
   # simple invert
   #
   case "${pattern}" in
      !*)
         pattern="${pattern:1}"
         YES=2   # negated
         NO=1    # doesn't match so we dont care
      ;;
   esac

   #
   # For things that look like a directory (trailing slash) we try to do it a little
   # differently. Otherwise its's pretty much just a tail match.
   #
   case "${pattern}" in
      ""|/)
         internal_fail "invalid pattern \"${pattern}\""
      ;;

      /*/)
         # support older bashes
         local snip

         snip="`sed -e 's/^.\(.*\).$/\1/' <<< "${pattern}" `"
         case "${text}" in
            ${snip}|${pattern:1}*)
               return $YES
            ;;
         esac
      ;;

      */)
         local snip

         snip="`sed -e 's/.$//' <<< "${pattern}" `"
         case "${text}" in
            ${snip}|${pattern}*|*/${pattern}*)
               return $YES
            ;;
         esac
      ;;

      /*)
         case "${text}" in
            ${pattern:1})
               return $YES
            ;;
         esac
      ;;

      *)
         case "${text}" in
            ${pattern}|*/${pattern})
               return $YES
            ;;
         esac
      ;;
   esac

   return $NO
}

#
# There is this weird bash bug on os x, where the patterns do
# not appear int the entry output. I don't know why.
# ```
# 1517521574.715441519 patternlines_match_relative_filename 'src/main.c', '', '"/tmp/a/.mulle-monitor/etc/source/patterns/90_SOURCES"'
# +++++ mulle-monitor-pattern.sh:143 + local 'patterns=*.c'
# ```
patternlines_match_relative_filename()
{
   log_entry "patternlines_match_relative_filename" "$@"

   local patterns="$1"
   local text="$2"
   local flags="$3"
   local where="$4"

   local pattern
   local rval

   rval=1
   IFS="
"
   for pattern in ${patterns}
   do
      IFS="${DEFAULT_IFS}"

      pattern_matches_relative_filename "${pattern}" "${text}" "${flags}"
      case "$?" in
         0)
            log_debug "Pattern \"${pattern}\" did match text \"${text}\""
            rval=0
         ;;

         2)
            log_debug "Pattern \"${pattern}\" negates \"${text}\""
            rval=1
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"

   if [ $rval -eq 1 ]
   then
      log_debug "Text \"${text}\" did not match any patterns in ${where}"
   fi

   return $rval
}


patternfile_read()
{
   log_entry "patternfile_read" "$@"

   local filename="$1"
   (
      shopt -s globstar 2> /dev/null # bash 4.0

      while read line
      do
         if [ -z "${line}" ]
         then
            continue
         fi

         echo "${line}"
      done < <( rexekutor egrep -v -s '^#' "${filename}" )
   )
}


patternfile_match_relative_filename()
{
   log_entry "patternfile_match_relative_filename" "$@"

   local filename="$1"
   local text="$2"
   local flags="$3"

   [ -z "${filename}" ] && internal_fail "filename is empty"
   [ -z "${text}" ]     && internal_fail "text is empty"

   case "${flags}" in
      *WM_CASEFOLD*)
         text="` tr 'A-Z' 'a-z' <<< "${text}" `"
      ;;
   esac

   local lines

   lines="` patternfile_read "${filename}" `"
   if [ -z "${lines}" ]
   then
      log_debug "\"${filename}\" does not exist or is empty"
      return 127
   fi

   patternlines_match_relative_filename "${lines}" \
                                        "${text}" \
                                        "${flags}" \
                                        "\"${filename}\""
}


_match_filepath()
{
   log_entry "_match_filepath" "$@"

   local match_dir="$1"
   local filepath="$2"

   local patternfile

   (
      cd "${match_dir}" || internal_fail "${match_dir} is gone"

      shopt -s nullglob
      for patternfile in [0-9]*_*
      do
         shopt -u nullglob
         if patternfile_match_relative_filename "${patternfile}" "${filepath}"
         then
            echo "${patternfile}"
            return 0
         fi
      done

      return 1
   )
}


match_filepath()
{
   log_entry "match_filepath" "$@"

   local ignore_dir="$1"
   local match_dir="$2"
   local filepath="$3"

   if [ ! -z "${ignore_dir}" ]
   then
      if _match_filepath "${ignore_dir}" "${filepath}" > /dev/null
      then
         return 1
      fi
   fi

   _match_filepath "${match_dir}" "${filepath}"
}



match_print_filepath()
{
   log_entry "match_print_filepath" "$@"

   local format="$1" ; shift
   local filename="$3" # sic

   local matchname

   if ! matchname="`match_filepath "$@" `"
   then
      return 1
   fi

   while [ ! -z "${format}" ]
   do
      case "${format}" in
         \%c*)
            format="${format:2}"
            printf "%s" "`sed -e 's/^[0-9]*_\(.*\)/\1/' <<< "${matchname}" `"
         ;;

         \%m*)
            format="${format:2}"
            printf "%s" "${matchname}"
         ;;

         \%f*)
            format="${format:2}"
            printf "%s" "${filename}"
         ;;

         \%n*)
            format="${format:2}"
            printf "%s" "`basename -- "${filename}"`"
         ;;

         \\n*)
            format="${format:2}"
            echo
         ;;

         *)
            printf "%s" "${format:0:1}"  # optimal... :P
            format="${format:1}"
         ;;
      esac
   done
}


match_environment()
{
   MULLE_MONITOR_DIR="${MULLE_MONITOR_DIR:-.mulle-monitor}"
   MULLE_MONITOR_ETC_DIR="${MULLE_MONITOR_ETC_DIR:-${MULLE_MONITOR_DIR}/etc}"

   MATCH_DIR="${MULLE_MONITOR_ETC_DIR}/mulle-monitor/match"
   if [ ! -d "${MATCH_DIR}" ]
   then
      MATCH_DIR="${MULLE_MONITOR_DIR}/share/mulle-monitor/match"
   fi
   if [ ! -d "${MATCH_DIR}" ]
   then
      fail "There is no directory \"$${MULLE_MONITOR_ETC_DIR}/mulle-monitor\" set up"
   fi

   IGNORE_DIR="${MULLE_MONITOR_ETC_DIR}/mulle-monitor/ignore"
   if [ ! -d "${IGNORE_DIR}" ]
   then
      IGNORE_DIR="${MULLE_MONITOR_DIR}/share/mulle-monitor/ignore"
      if [ ! -d "${IGNORE_DIR}" ]
      then
         IGNORE_DIR=""
      fi
   fi
}



###
###  MAIN
###
monitor_match_main()
{
   log_entry "monitor_match_main" "$@"

   local OPTION_FORMAT="c\\n"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            monitor_match_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            cd "$1" || exit 1
         ;;

         --format)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            OPTION_FORMAT="$1"
         ;;

         -*)
            monitor_match_usage "unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   local rval

   match_environment

   [ "$#" -ne 1 ] && monitor_match_usage "missing filename"

   local rval

   rval=0

   while [ $# -ne 0 ]
   do
      if match_print_filepath "${OUTPUT_FORMAT}" "${IGNORE_DIR}" "${MATCH_DIR}" "$1"
      then
         if [ $rval -ne 0 ]
         then
            rval=2
         fi
      else
         rval=1
      fi

      shift
   done

   return $rval
}
