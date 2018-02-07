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
                        %I : category of match file as an uppercase identifier
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



# this is a nicety for scripts that run find
find_emit_common_directories()
{
   log_entry "find_emit_common_directories" "$@"

   local items="$1"
   local emitter="$2"
   local parameter="$3"

   [ -z "${emitter}" ] && internal_fail "emitter is empty"

   local collection

   collection="`sed -n -e 's|^[^;]*;\(.*\)/[^/]*\.h|\1|p' <<< "${items}" | sort -u`"

   if [ ! -z "${collection}" ]
   then
      "${emitter}" "${parameter}" "${collection}"
   fi
}


# this is a nicety for scripts that run find
find_emit_by_category()
{
   log_entry "find_emit_by_category" "$@"

   local items="$1"
   local emitter="$2"

   [ -z "${emitter}" ] && internal_fail "emitter is empty"

   local collectname
   local collection
   local remainder

   remainder="${items}"

   while [ ! -z "${remainder}" ]
   do
      collectname="`sed -n -e '/\(^[^;]*\).*/{s//\1/p;q}' <<< "${remainder}" `"
      collection="`egrep "^${collectname};" <<< "${remainder}" | cut -d ';' -f 2-`"
      "${emitter}" "${collectname}" "${collection}"

      remainder="`egrep -v "^${collectname};" <<< "${remainder}" `"
   done

   :
}


get_core_count()
{
   local count

   count="`nproc 2> /dev/null`"
   if [ -z "$count" ]
   then
      count="`sysctl -n hw.ncpu 2> /dev/null`"
   fi

   if [ -z "$count" ]
   then
      count=2
   fi
   echo $count
}


_find_filenames()
{
   log_entry "_find_filenames" "$@"

   local format="$1"
   local ignore_patterncaches="$2"
   local match_patterncaches="$3"

   #
   # to reduce the search tree, first do a search in root only
   # and drop all ignored stuff
   #
   local quoted_filenames
   local filename

   IFS="
"
   for filename in `find . -mindepth 1 -maxdepth 1 -print`
   do
      IFS="${DEFAULT_IFS}"
      match_filepath "${ignore_patterncaches}" \
                      "" \
                      "${filename:2}" > /dev/null

      # 0 would be matched, but we have no match_dir
      if [ $? -eq 2 ]
      then
         quoted_filenames="`concat "${quoted_filenames}" "'${filename:2}'"`"
      fi
   done
   IFS="${DEFAULT_IFS}"

   if [ -z "${quoted_filenames}" ]
   then
      return 1
   fi

   #
   # now with that out of the way, lets go
   #
   local filenames
   local filename

   local maxjobs

   maxjobs=`get_core_count`

   IFS="
"
   for filename in `eval_exekutor find ${quoted_filenames} -type f -print`
   do
      IFS="${DEFAULT_IFS}"

      while [ `jobs -pr | wc -l` -ge ${maxjobs} ]
      do
         sleep 0.01s # 100Hz
      done

      match_print_filepath "${format}" \
                           "${ignore_patterncaches}" \
                           "${match_patterncaches}" \
                           "${filename}" &

      shift
   done
   IFS="${DEFAULT_IFS}"

   log_verbose "waiting..."
   wait
   log_verbose 'done!'
}



find_filenames()
{
   log_entry "_find_filenames" "$@"

   _find_filenames "$@" | sort
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

   local _cache

   _patterncaches_passing_filter "${MULLE_MONITOR_IGNORE_DIR}" \
                                 "${OPTION_IGNORE_FILTER}"
   ignore_patterncaches="${_cache}"

   _patterncaches_passing_filter "${MULLE_MONITOR_MATCH_DIR}" \
                                 "${OPTION_MATCH_FILTER}"
   match_patterncaches="${_cache}"


   find_filenames "${OUTPUT_FORMAT}" \
                  "${ignore_patterncaches}" \
                  "${match_patterncaches}"
}
