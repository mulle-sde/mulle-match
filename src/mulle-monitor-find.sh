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
MULLE_MONITOR_FIND_SH="included"


monitor_find_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} find [options]

   Find matching files in the project directory.

Options:
   -d <dir>       : project directory (parent of .mulle-monitor)
   -f <format>    : specify output values
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" ]
   then
     cat <<EOF >&2
                    This is like a simplified C printf format:
                        %c : category of match file (can be empty)
                        %e : executable name of callback
                        %f : filename that was matched
                        %m : the full match filename
                        %t : type of match file
                        \\n : a linefeed
                     (e.g. "category=%c,type=%t\\n)"
EOF
   fi

   cat <<EOF >&2
   -if <filter>   : specify a filter for ignoring <type>
   -mf <filter>   : specify a filter for matching <type>
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" ]
   then
     cat <<EOF >&2
                    A filter is a comma separated list of type expressions.
                    A type expression is either a type name with wildcard
                    characters or a negated type expression. An expression is
                    negated by being prefixed with !.
                    Example: filter is "header*,!header_private"
EOF
   fi
   exit 1
}


find_filenames()
{
   log_entry "find_filenames" "$@"

   local format="$1"
   local ignore_dir="$2"
   local ignore_filter="$3"
   local match_dir="$4"
   local match_filter="$5"

   #
   # to reduce the search tree, first do a search in root only
   # and drop all ignored stuff
   #
   local quoted_filenames
   local filename

   IFS="
"
   for filename in `rexekutor find . -mindepth 1 -maxdepth 1 -print`
   do
      IFS="${DEFAULT_IFS}"
      if match_filepath "${ignore_dir}" \
                        "${ignore_filter}"  \
                        "" \
                        "" \
                        "${filename}"
      then
         quoted_filenames="`concat "${quoted_filenames}" "'${filename:2}'"`"
      fi
   done
   IFS="${DEFAULT_IFS}"

   if [ -z "${quoted_filenames}" ]
   then
      return 1
   fi

   # now with that out of the way, lets go
   local filenames
   local filename
   local rval

   rval=0

   IFS="
"
   for filename in `eval_exekutor find ${quoted_filenames} -type f -print`
   do
      IFS="${DEFAULT_IFS}"
      if match_print_filepath "${format}" \
                              "${ignore_dir}" \
                              "${ignore_filter}" \
                              "${match_dir}" \
                              "${match_filter}" \
                              "${filename}"
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
   IFS="${DEFAULT_IFS}"

   return $rval
}


###
###  MAIN
###
monitor_find_main()
{
   log_entry "monitor_find_main" "$@"

   local OPTION_FORMAT="%f;%c\\n"

   local OPTION_MATCH_FILTER
   local OPTION_IGNORE_FILTER

   local MATCH_DIR
   local IGNORE_DIR

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            monitor_find_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && monitor_find_usage "missing argument to $1"
            shift

            cd "$1" || exit 1
         ;;

         -id|--ignore-dir)
            [ $# -eq 1 ] && monitor_find_usage "missing argument to $1"
            shift

            IGNORE_DIR="$1"
         ;;

         -md|--match-dir)
            [ $# -eq 1 ] && monitor_find_usage "missing argument to $1"
            shift

            MATCH_DIR="$1"
         ;;

         -if|--ignore-filter)
            [ $# -eq 1 ] && monitor_find_usage "missing argument to $1"
            shift

            OPTION_IGNORE_FILTER="$1"
         ;;

         -mf|--match-filter)
            [ $# -eq 1 ] && monitor_find_usage "missing argument to $1"
            shift

            OPTION_MATCH_FILTER="$1"
         ;;

         --format)
            [ $# -eq 1 ] && monitor_find_usage "missing argument to $1"
            shift

            OPTION_FORMAT="$1"
         ;;

         -*)
            monitor_find_usage "unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 0 ] && monitor_find_usage "superflous arguments \"$*\""

   if [ -z "${MULLE_MONITOR_MATCH_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-match.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-match.sh" || exit 1
   fi

   match_environment

   find_filenames "${OUTPUT_FORMAT}" \
                  "${IGNORE_DIR}" \
                  "${OPTION_IGNORE_FILTER}" \
                  "${MATCH_DIR}" \
                  "${OPTION_MATCH_FILTER}"
}
