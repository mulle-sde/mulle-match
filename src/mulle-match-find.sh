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
MULLE_MATCH_FIND_SH="included"


match_find_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} find [options]

   Find files matching the patternfiles in the project directory.

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
      # https://stackoverflow.com/questions/1773939/how-to-use-sed-to-return-something-from-first-line-which-matches-and-quit-early
      collectname="`sed -n -e '/\(^[^;]*\).*/{s//\1/p;q;}' <<< "${remainder}" `"
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
      count=4
      log_verbose "Unknown core count, setting it to 4 as default"
   fi
   echo $count
}


_find_toplevel_files()
{
   log_entry "_find_toplevel_files" "$@"

   local ignore="$1"

   local filenames
   local filename

   #
   # to reduce the search tree, first do a search in root only
   # and drop all ignored stuff
   #
   local quoted_filenames
   local filename
   local _patternfile # needed for _match_filepath

   for filename in .* *
   do
      if [ "${filename}" = "." -o "${filename}" = ".." ]
      then
         continue
      fi

      _match_filepath "${ignore}" "" "${filename}"

      # 0 would be matched, but we have no match_dir
      # so fall through ignore means 2
      if [ $? -eq 2 ]
      then
         echo "'${filename}'"
      fi
   done
}


_parallel_find_filtered_files()
{
   log_entry "_parallel_find_filtered_files" "$@"

   local quoted_filenames="$1"
   local format="$2"
   local filter="$3"
   local ignore="$4"
   local match="$5"

   local maxjobs
   local running

   maxjobs=`get_core_count`

   local filename_0
   local filename_1
   local filename_2
   local filename_3
   local filename_4
   local filename_5
   local filename_6
   local filename_7
   local filename_8
   local filename_9
   local filename_a
   local filename_b
   local filename_c
   local filename_d
   local filename_e
   local filename_f

   IFS="
"
   while read -r filename_0
   do
      read -r filename_1
      read -r filename_2
      read -r filename_3
      read -r filename_4
      read -r filename_5
      read -r filename_6
      read -r filename_7
      read -r filename_8
      read -r filename_9
      read -r filename_a
      read -r filename_b
      read -r filename_c
      read -r filename_d
      read -r filename_e
      read -r filename_f

      IFS="${DEFAULT_IFS}"

     while :
     do
        running=($(jobs -pr))  #  http://mywiki.wooledge.org/BashFAQ/004
        if [ "${#running[@]}" -le ${maxjobs} ]
        then
           break
        fi
        sleep 0.01s # 100Hz
     done

     (
         match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_0}"

         [ ! -z "${filename_1}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_1}"
         [ ! -z "${filename_2}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_2}"
         [ ! -z "${filename_3}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_3}"

         [ ! -z "${filename_4}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_4}"
         [ ! -z "${filename_5}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_5}"
         [ ! -z "${filename_6}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_6}"
         [ ! -z "${filename_7}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_7}"

         [ ! -z "${filename_8}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_8}"
         [ ! -z "${filename_9}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_9}"
         [ ! -z "${filename_a}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_a}"
         [ ! -z "${filename_b}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_b}"

         [ ! -z "${filename_c}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_c}"
         [ ! -z "${filename_d}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_d}"
         [ ! -z "${filename_e}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_e}"
         [ ! -z "${filename_f}" ] && match_print_filepath "${format}" "${filter}" "${ignore}" "${match}" "${filename_f}"
      ) &

      shift
   done < <( set -o noglob; eval_exekutor find ${quoted_filenames} -type f -print )
   IFS="${DEFAULT_IFS}"

   log_verbose "waiting..."
   wait
   log_verbose 'done!'
}


_find_filenames()
{
   log_entry "_find_filenames" "$@"

   local format="$1"
   local filter="$2"
   local ignore="$3"
   local match="$4"

   #
   # now with that out of the way, lets go
   #
   local quoted_filenames

   quoted_filenames="`_find_toplevel_files "${ignore}"`"
   if [ -z "${quoted_filenames}" ]
   then
      return 1
   fi

   _parallel_find_filtered_files "${quoted_filenames}" \
                                 "${format}" \
                                 "${filter}" \
                                 "${ignore}" \
                                 "${match}"
}



find_filenames()
{
   log_entry "_find_filenames" "$@"

   _find_filenames "$@" | sort
}


###
###  MAIN
###
match_find_main()
{
   log_entry "match_find_main" "$@"

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

   local OPTION_FORMAT="%f\\n"

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
         -h*|--help|help)
            match_find_usage
         ;;

         -mf|--match-filter)
            [ $# -eq 1 ] && match_find_usage "missing argument to $1"
            shift

            OPTION_MATCH_FILTER="$1"
         ;;

         -f|--format)
            [ $# -eq 1 ] && match_find_usage "missing argument to $1"
            shift

            OPTION_FORMAT="$1"
         ;;

         -*)
            match_find_usage "unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 0 ] && match_find_usage "superflous arguments \"$*\""

   if [ -z "${MULLE_MATCH_MATCH_SH}" ]
   then
      # shellcheck source=src/mulle-match-match.sh
      . "${MULLE_MATCH_LIBEXEC_DIR}/mulle-match-match.sh" || exit 1
   fi

   local _cache
   local ignore_patterncache
   local match_patterncache

   _define_patternfilefunctions "${MULLE_MATCH_IGNORE_DIR}" \
                                "${MULLE_MATCH_DIR}/var/cache/match"
   ignore_patterncache="${_cache}"

   _define_patternfilefunctions "${MULLE_MATCH_MATCH_DIR}" \
                                "${MULLE_MATCH_DIR}/var/cache/match"
   match_patterncache="${_cache}"


   find_filenames "${OPTION_FORMAT}" \
                  "${OPTION_MATCH_FILTER}" \
                  "${ignore_patterncache}" \
                  "${match_patterncache}"
}
