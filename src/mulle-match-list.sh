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
MULLE_MATCH_LIST_SH="included"


match_list_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} list [options]

   List files that match the rules contained in the patternfiles of the project
   directory.

   For good performance it is important to restrict the searched items as much
   as possible using the environment variables. You can further restrict the
   output, by only matching certian patternfile types.

   The following example searches for C source files in 'src' and 'foo/src':

      MULLE_MATCH_FILENAMES="*.c:*.h" \\
      MULLE_MATCH_PATH="src:foo/src" \\
         ${MULLE_USAGE_NAME} list --mf source

Options:
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
     cat <<EOF >&2
   -f <format>    : specify output values
                    This is like a simplified C printf format:
                        %c : category of match file (can be empty)
                        %e : executable name of callback
                        %f : filename that was matched
                        %m : the full match filename
                        %t : type of match file
                        %I : category of match file as an uppercase identifier
                        \\n : a linefeed
                     (e.g. "category=%c,type=%t\\n")
EOF
   else
     cat <<EOF >&2
   -f <format>    : specify output values (-v for detailed help)
EOF
   fi

   cat <<EOF >&2
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
     cat <<EOF >&2
   -mf <filter>   : specify a filter for matching <type>
                    A filter is a comma separated list of type expressions.
                    A type expression is either a type name with wildcard
                    characters or a negated type expression. An expression is
                    negated by being prefixed with !.
                    Example: filter is "header*,!header_private"
EOF
   else
     cat <<EOF >&2
   -mf <filter>   : specify a filter for matching <type> (-v for detailed help)
EOF
   fi

     cat <<EOF >&2

Environment:
   MULLE_MATCH_FILENAMES   : filename wildcards, separated by ':'   (*)
   MULLE_MATCH_IGNORE_PATH : locations to ignore
   MULLE_MATCH_PATH        : locations to search for, separated by ':'' (src)

EOF
   exit 1
}



# this is a nicety for scripts that run find
list_emit_common_directories()
{
   log_entry "list_emit_common_directories" "$@"

   local items="$1"
   local emitter="$2"
   local parameter="$3"

   [ -z "${emitter}" ] && internal_fail "emitter is empty"

   local collection

   collection="`sed -n -e 's|^[^;]*;\(.*\)/[^/]*\.h|\1|p' <<< "${items}" | LC_ALL=C sort -u`"

   if [ ! -z "${collection}" ]
   then
      "${emitter}" "${parameter}" "${collection}"
   fi
}


# this is a nicety for scripts that run find
list_emit_by_category()
{
   log_entry "list_emit_by_category" "$@"

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


_list_toplevel_files()
{
   log_entry "_list_toplevel_files" "$@"

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
      # so fall through ignore means 4
      if [ $? -eq 4 ]
      then
         echo "'${filename}'"
      fi
   done
}


parallel_list_filtered_files()
{
   log_entry "parallel_list_filtered_files" "$@"

   local quoted_filenames="$1" ; shift
   local format="$1" ; shift
   local tfilter="$1" ; shift
   local cfilter="$1" ; shift
   local ignore="$1" ; shift
   local match="$1" ; shift
   local flags="$1" ; shift

   [ -z "${MULLE_PARALLEL_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-parallel.sh"

   local maxjobs
   local running

   r_get_core_count
   maxjobs="${RVAL}"

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
   local filename_10
   local filename_11
   local filename_12
   local filename_13
   local filename_14
   local filename_15
   local filename_16
   local filename_17
   local filename_18
   local filename_19
   local filename_1a
   local filename_1b
   local filename_1c
   local filename_1d
   local filename_1e
   local filename_1f

   log_debug "Search locations: ${quoted_filenames}"

   shopt -s extglob
   set -o noglob

   while IFS=$'\n' read -r filename_0
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
      read -r filename_10
      read -r filename_11
      read -r filename_12
      read -r filename_13
      read -r filename_14
      read -r filename_15
      read -r filename_16
      read -r filename_17
      read -r filename_18
      read -r filename_19
      read -r filename_1a
      read -r filename_1b
      read -r filename_1c
      read -r filename_1d
      read -r filename_1e
      read -r filename_1f

      wait_for_available_job "${maxjobs}"

      (
         _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_0}"

         [ ! -z "${filename_1}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_1}"
         [ ! -z "${filename_2}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_2}"
         [ ! -z "${filename_3}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_3}"

         [ ! -z "${filename_4}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_4}"
         [ ! -z "${filename_5}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_5}"
         [ ! -z "${filename_6}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_6}"
         [ ! -z "${filename_7}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_7}"

         [ ! -z "${filename_8}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_8}"
         [ ! -z "${filename_9}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_9}"
         [ ! -z "${filename_a}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_a}"
         [ ! -z "${filename_b}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_b}"

         [ ! -z "${filename_c}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_c}"
         [ ! -z "${filename_d}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_d}"
         [ ! -z "${filename_e}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_e}"
         [ ! -z "${filename_f}" ]  && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_f}"

         [ ! -z "${filename_10}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_10}"
         [ ! -z "${filename_11}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_11}"
         [ ! -z "${filename_12}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_12}"
         [ ! -z "${filename_13}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_13}"

         [ ! -z "${filename_14}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_14}"
         [ ! -z "${filename_15}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_15}"
         [ ! -z "${filename_16}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_16}"
         [ ! -z "${filename_17}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_17}"

         [ ! -z "${filename_18}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_18}"
         [ ! -z "${filename_19}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_19}"
         [ ! -z "${filename_1a}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_1a}"
         [ ! -z "${filename_1b}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_1b}"

         [ ! -z "${filename_1c}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_1c}"
         [ ! -z "${filename_1d}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_1d}"
         [ ! -z "${filename_1e}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_1e}"
         [ ! -z "${filename_1f}" ] && _match_print_filepath "${format}" "${tfilter}" "${cfilter}" "${ignore}" "${match}" "${filename_1f}"
      ) &

   done < <( eval_exekutor find ${flags} ${quoted_filenames} "$@" -print \
               | LC_ALL="C" rexekutor sed -e 's|^\./||g' \
               | LC_ALL="C" rexekutor sort -u )

   set +o noglob

   log_fluff "Waiting for jobs to finish..."
   wait
   log_fluff 'All jobs finished'
}


list_filenames()
{
   log_entry "list_filenames" "$@"

   local format="$1"
   local tfilter="$2"
   local cfilter="$3"
   local ignore="$4"
   local match="$5"

   local name
   local ignore_dirs
   local match_files
   local match_dirs

   #
   # MULLE_MATCH_PATH: This is where the find search starts
   #
   if [ -z "${MULLE_MATCH_PATH}" ]
   then
      MULLE_MATCH_PATH=".mulle/etc/sourcetree/config:src"
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "Default MULLE_MATCH_PATH: ${MULLE_MATCH_PATH}"
      fi
   else
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "MULLE_MATCH_PATH: ${MULLE_MATCH_PATH}"
      fi
   fi

   IFS=':'
   set -o noglob # turn off globbing temporarily

   for name in ${MULLE_MATCH_PATH}
   do
      if [ -e "${name}" ]
      then
         r_concat "${match_dirs}" "'${name}'"
         match_dirs="${RVAL}"
      fi
   done

   #
   # MULLE_MATCH_IGNORE_PATH: These are subdirectories that get
   # ignored. This can be  important for acceptable performance and easier
   # setup
   #
   if [ -z "${MULLE_MATCH_IGNORE_PATH}" ]
   then
      MULLE_MATCH_IGNORE_PATH="addiction:\
build:\
kitchen:\
dependency:\
stash:\
include:\
lib:\
libexec:\
.mulle:\
.git"
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "Default MULLE_MATCH_IGNORE_PATH: ${MULLE_MATCH_IGNORE_PATH}"
      fi
   else
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "MULLE_MATCH_IGNORE_PATH: ${MULLE_MATCH_IGNORE_PATH}"
      fi
   fi

   for name in ${MULLE_MATCH_IGNORE_PATH}
   do
      r_concat "${ignore_dirs}" "-path '${name}'" " -o "
      ignore_dirs="${RVAL}"
   done

   #
   # MULLE_MATCH_FILENAMES: Even more important for acceptable perfomance is
   # to only match interesting filenames
   #
   if [ -z "${MULLE_MATCH_FILENAMES}" ]
   then
      match_files="-name '*'"
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "Default MULLE_MATCH_FILENAMES: ${MULLE_MATCH_FILENAMES}"
      fi
   else
      for name in ${MULLE_MATCH_FILENAMES}
      do
         r_concat "${match_files}" "-name '$name'" " -o "
         match_files="${RVAL}"
      done

      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "MULLE_MATCH_FILENAMES: ${MULLE_MATCH_FILENAMES}"
      fi
   fi

   set +o noglob
   IFS="${DEFAULT_IFS}"

   # use xtype to also catch symlinks to files

   local flags
   local query

   query="-xtype f"
   case "${MULLE_UNAME}" in
      darwin|freebsd)
         query='\( -type f -o -type l \)'
      ;;
   esac

   parallel_list_filtered_files "${match_dirs:-.}" \
                                "${format}" \
                                "${tfilter}" \
                                "${cfilter}" \
                                "${ignore}" \
                                "${match}" \
                                "${flags}" \
                                "\\(" ${ignore_dirs} "\\)" -prune  \
                                -o \
                                ${query} \
                                "\\(" ${match_files} "\\)"
}


match_list_include()
{
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

   if [ -z "${MULLE_MATCH_MATCH_SH}" ]
   then
      # shellcheck source=src/mulle-match-match.sh
      . "${MULLE_MATCH_LIBEXEC_DIR}/mulle-match-match.sh" || exit 1
   fi
}


###
###  MAIN
###
match_list_main()
{
   log_entry "match_list_main" "$@"


   local OPTION_FORMAT="%f\\n"
   local OPTION_SORTED='YES'
   local OPTION_MATCH_TYPE_FILTER
   local OPTION_MATCH_CATEGORY_FILTER

   local MATCH_DIR
   local IGNORE_DIR

   # backwards compatibility

   MULLE_MATCH_PATH="${MULLE_MATCH_PATH:-${MULLE_MATCH_FIND_LOCATIONS}}"
   MULLE_MATCH_IGNORE_PATH="${MULLE_MATCH_IGNORE_PATH:-${MULLE_MATCH_FIND_IGNORE_PATH}}"
   MULLE_MATCH_FILENAMES="${MULLE_MATCH_FILENAMES:-${MULLE_MATCH_FILENAMES}}"


   match_list_include

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            match_list_usage
         ;;

         -mf|--match-filter|-tf|--type-filter)
            [ $# -eq 1 ] && match_list_usage "missing argument to $1"
            shift

            OPTION_MATCH_TYPE_FILTER="$1"
         ;;

         -cf|--category-filter)
            [ $# -eq 1 ] && match_list_usage "missing argument to $1"
            shift

            OPTION_MATCH_CATEGORY_FILTER="$1"
         ;;

         --locations)
            [ $# -eq 1 ] && match_list_usage "missing argument to $1"
            shift

            MULLE_MATCH_PATH="$1"
         ;;

         --ignore-path)
            [ $# -eq 1 ] && match_list_usage "missing argument to $1"
            shift

            MULLE_MATCH_IGNORE_PATH="$1"
         ;;

         --match-names)
            [ $# -eq 1 ] && match_list_usage "missing argument to $1"
            shift

            MULLE_MATCH_FILENAMES="$1"
         ;;

         -f|--format)
            [ $# -eq 1 ] && match_list_usage "missing argument to $1"
            shift

            OPTION_FORMAT="$1"
         ;;

         -u|--unsorted)
            OPTION_SORTED='NO'
         ;;

         -*)
            match_list_usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 0 ] && match_list_usage "superflous arguments \"$*\""


   local _cache
   local skip_patterncache
   local use_patterncache

   [ -z "${MULLE_MATCH_VAR_DIR}" ] && internal_fail "MULLE_MATCH_VAR_DIR not set"

   _define_patternfilefunctions "${MULLE_MATCH_SKIP_DIR}" \
                                "${MULLE_MATCH_VAR_DIR}/cache/match"
   skip_patterncache="${_cache}"

   _define_patternfilefunctions "${MULLE_MATCH_USE_DIR}" \
                                "${MULLE_MATCH_VAR_DIR}/cache/match"
   use_patterncache="${_cache}"

   if [ "${OPTION_SORTED}" = 'YES' ]
   then
      list_filenames "${OPTION_FORMAT}" \
                     "${OPTION_MATCH_TYPE_FILTER}" \
                     "${OPTION_MATCH_CATEGORY_FILTER}" \
                     "${skip_patterncache}" \
                     "${use_patterncache}" | LC_ALL=C sort
   else
      list_filenames "${OPTION_FORMAT}" \
                     "${OPTION_MATCH_TYPE_FILTER}" \
                     "${OPTION_MATCH_CATEGORY_FILTER}" \
                     "${skip_patterncache}" \
                     "${use_patterncache}"
   fi
}
