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

   A match file has the form 00-type--category.

Options:
   -d <dir>       : project directory (parent of .mulle-monitor)
   -f <format>    : specify output values.
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



#
# This is pretty similiar to.gitignore. For most purposes it should
# be identical. It doesn't work with
#
pattern_matches_relative_filename()
{
   log_entry "pattern_matches_relative_filename" "$@"

   local pattern="$1"
   local filename="$2"
   local flags="$3"

   #
   # if we are strict on text input, we can simplify pattern handling
   # a lot. Note that we only deal with relative paths anyway
   #
   case "${filename}" in
      "")
         internal_fail "Empty filename is illegal"
      ;;

      /*)
         internal_fail "Filename \"${filename}\" is illegal. It must not start with '/'"
      ;;

      */)
         internal_fail "Filename \"${filename}\" is illegal. It must not end with '/'"
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
         case "${filename}" in
            ${snip}|${pattern:1}*)
               return $YES
            ;;
         esac
      ;;

      */)
         local snip

         snip="`sed -e 's/.$//' <<< "${pattern}" `"
         case "${filename}" in
            ${snip}|${pattern}*|*/${pattern}*)
               return $YES
            ;;
         esac
      ;;

      /*)
         case "${filename}" in
            ${pattern:1})
               return $YES
            ;;
         esac
      ;;

      *)
         case "${filename}" in
            ${pattern}|*/${pattern})
               return $YES
            ;;
         esac
      ;;
   esac

   return $NO
}


patternlines_match_relative_filename()
{
   log_entry "patternlines_match_relative_filename" "$@"

   local patterns="$1"
   local filename="$2"
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

      pattern_matches_relative_filename "${pattern}" "${filename}" "${flags}"
      case "$?" in
         0)
            log_debug "pattern \"${pattern}\" did match filename \"${filename}\""
            rval=0
         ;;

         2)
            log_debug "pattern \"${pattern}\" negates filename \"${filename}\""
            rval=1
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"

   if [ $rval -eq 1 ]
   then
      log_debug "filename \"${filename}\" did not match any patterns in ${where}"
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

   local patternfilename="$1"
   local filename="$2"
   local flags="$3"

   [ -z "${patternfilename}" ] && internal_fail "patternfilename is empty"
   [ -z "${filename}" ]        && internal_fail "filename is empty"

   case "${flags}" in
      *WM_CASEFOLD*)
         text="` tr 'A-Z' 'a-z' <<< "${filename}" `"
      ;;
   esac

   local lines

   lines="` patternfile_read "${patternfilename}" `"
   if [ -z "${lines}" ]
   then
      log_debug "\"${patternfilename}\" does not exist or is empty"
      return 127
   fi

   patternlines_match_relative_filename "${lines}" \
                                        "${filename}" \
                                        "${flags}" \
                                        "\"${patternfilename}\""
}


#
# a filter is
# <filter> : <texpr>  | <filter> , <texpr>
# <texpr>  : ! <type> | <type>
#
# Think about using pattern_matches_relative_filename for this
#
filter_patternfilename()
{
   local filter="$1"
   local patternfile="$2"

   local texpr
   local shouldmatch


   IFS=","
   for texpr in ${filter}
   do
      IFS="${DEFAULT_IFS}"

      shouldmatch="YES"
      case "${texpr}" in
         !*)
            shouldmatch="NO"
            texpr="${texpr:1}"
         ;;
      esac

      match="[0-9]*-${texpr}--*"

      case "${patternfile}" in
         ${match})
            if [ "${shouldmatch}" = "NO" ]
            then
               return 1
            fi
         ;;

         *)
            if [ "${shouldmatch}" = "YES" ]
            then
               return 1
            fi
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"

   return 0
}


matchfile_get_type()
{
   log_entry "matchfile_get_type" "$@"

   local filename="$1"

   sed -n -e 's/^[0-9]*-\([^-].*\)--.*/\1/p' <<< "${filename}"
}


matchfile_get_category()
{
   log_entry "matchfile_get_category" "$@"

   local filename="$1"

   sed -n -e 's/^[0-9]*-[^-]*--\(.*\)/\1/p' <<< "${filename}"
}


_match_filepath()
{
   log_entry "_match_filepath" "$@"

   local directory="$1"
   local filter="$2"
   local filepath="$3"

   [ -z "${directory}" ] && internal_fail "directory is empty"
   [ -z "${filepath}" ]  && internal_fail "filepath is empty"

   (
      exekutor cd "${directory}" || internal_fail "failed to cd to \"$1\" from \"${PWD}\""

      local patternfile

      shopt -s nullglob
      for patternfile in [0-9]*-*--*
      do
         shopt -u nullglob
         if [ ! -z "${filter}" ] && ! filter_patternfilename  "${filter}" "${patternfile}"
         then
            log_debug "\"${patternfile}\" did not pass filter"
            continue
         fi
         if patternfile_match_relative_filename "${patternfile}" "${filepath}"
         then
            exekutor echo "${patternfile}"
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
   local ignore_filter="$2"
   local match_dir="$3"
   local match_filter="$4"
   local filepath="$5"

   if [ ! -z "${ignore_dir}" ]
   then
      if _match_filepath "${ignore_dir}" "${ignore_filter}" "${filepath}" > /dev/null
      then
         log_debug "\"${filepath}\" ignored"
         return 1
      fi
   fi
   log_debug "\"${filepath}\" not ignored"

   if [ ! -z "${match_dir}" ]
   then
      if _match_filepath "${match_dir}" "${match_filter}" "${filepath}"
      then
         log_debug "\"${filepath}\" matched"
         return 0
      fi
      log_debug "\"${filepath}\" did not match"
      return 1
   fi

   log_debug "\"${filepath}\" always matches"
   return 0
}


match_print_filepath()
{
   log_entry "match_print_filepath" "$@"

   local format="$1" ; shift
   local filename="$5" # sic

   local matchname

   if ! matchname="`match_filepath "$@" `"
   then
      return 1
   fi

   local matchtype
   local matchcategory

   matchtype="`matchfile_get_type "${matchname}" `"
   matchcategory="`matchfile_get_category "${matchname}" `"

   [ -z "${matchtype}" ] && internal_fail "should not happen"

   while [ ! -z "${format}" ]
   do
      case "${format}" in
         \%c*)
            format="${format:2}"
            printf "%s" "${matchcategory}"
         ;;

         \%e*)
            format="${format:2}"
            printf "%s%s" "${matchtype}" "did-update"
         ;;

         \%f*)
            format="${format:2}"
            printf "%s" "${filename}"
         ;;

         \%m*)
            format="${format:2}"
            printf "%s" "${matchname}"
         ;;

         \%t*)
            format="${format:2}"
            printf "%s" "${matchtype}"
         ;;

         \%I*)
            format="${format:2}"
            printf "%s" "`tr 'a-z' 'A-Z' <<< "${matchcategory}" | tr '-' '_' `"
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
   log_entry "monitor_match_main" "$@"

   MULLE_MONITOR_DIR="${MULLE_MONITOR_DIR:-.mulle-monitor}"
   MULLE_MONITOR_ETC_DIR="${MULLE_MONITOR_ETC_DIR:-${MULLE_MONITOR_DIR}/etc}"

   case "${MATCH_DIR}" in
      NO)
         MATCH_DIR=""
      ;;

      "")
         MATCH_DIR="${MULLE_MONITOR_ETC_DIR}/mulle-monitor/match.d"
         if [ ! -d "${MATCH_DIR}" ]
         then
            MATCH_DIR="${MULLE_MONITOR_DIR}/share/mulle-monitor/match.d"
         fi
         if [ ! -d "${MATCH_DIR}" ]
         then
            MATCH_DIR=""
            log_warning "There is no directory \"${MULLE_MONITOR_ETC_DIR}/mulle-monitor\" set up"
         fi
      ;;
   esac

   case "${IGNORE_DIR}" in
      NO)
         IGNORE_DIR=""
      ;;

      "")
         IGNORE_DIR="${MULLE_MONITOR_ETC_DIR}/mulle-monitor/ignore.d"
         if [ ! -d "${IGNORE_DIR}" ]
         then
            IGNORE_DIR="${MULLE_MONITOR_DIR}/share/mulle-monitor/ignore.d"
         fi
         if [ ! -d "${IGNORE_DIR}" ]
         then
            IGNORE_DIR=""
         fi
      ;;
   esac
}


###
###  MAIN
###
monitor_match_main()
{
   log_entry "monitor_match_main" "$@"

   local OPTION_FORMAT="%t\\n"
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
            monitor_match_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            exekutor cd "$1" || fail "failed to cd to \"$1\" from \"${PWD}\""
         ;;

         -id|--ignore-dir)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            IGNORE_DIR="$1"
         ;;

         -md|--match-dir)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            MATCH_DIR="$1"
         ;;

         -if|--ignore-filter)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            OPTION_IGNORE_FILTER="$1"
         ;;

         -mf|--match-filter)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            OPTION_MATCH_FILTER="$1"
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
      if match_print_filepath "${OPTION_FORMAT}" \
                              "${IGNORE_DIR}" \
                              "${OPTION_IGNORE_FILTER}" \
                              "${MATCH_DIR}" \
                              "${OPTION_MATCH_FILTER}" \
                              "$1"
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
