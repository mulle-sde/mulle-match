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
   cat <<EOF >&2
   -p <pattern>   : match a single pattern against a single filename
EOF
   fi
   exit 1
}

#
# For things that look like a directory (trailing slash) we try to do it a
# little differently. Otherwise its's pretty much just a tail match.
# the '!' is multiplied out for performance reasons
#
_match_assert_pattern()
{
   log_entry "_match_assert_pattern" "$@"

   local pattern="$1"

   case "${pattern}" in
      "")
         internal_fail "Empty pattern is illegal"
      ;;

      *//*)
         internal_fail "Pattern \"${pattern}\" is illegal. It must not contain  \"//\""
      ;;
   esac
}


pattern_emit_matchcode()
{
   log_entry "pattern_emit_matchcode" "$@"

   local pattern="$1"

   local YES=0
   local NO=1

   #
   # simple invert
   #
   case "${pattern}" in
      !!*)
         # consider that an escape for whatever purpose
      ;;

      !*)
         pattern="${pattern:1}"
         YES=2   # negated
         NO=1    # doesn't match so we dont care
      ;;
   esac


   _match_assert_pattern "${pattern}"

   case "${pattern}" in
      /*/)
         # support older bashes
         local snip

         snip="${pattern:1}"
         snip="${snip%?}"

         cat <<EOF
   case "\$1" in
      ${snip}|${pattern:1}*)
         return $YES
      ;;
   esac
   return $NO
EOF
      ;;

      /*)
         cat <<EOF
   case "\$1" in
      ${pattern:1})
         return $YES
      ;;
   esac
   return $NO
EOF
      ;;

      */)
         cat <<EOF
   case "\$1" in
      ${pattern%?}|${pattern}*|*/${pattern}*)
         return $YES
      ;;
   esac
   return $NO
EOF
      ;;

      *)
         cat <<EOF
   case "\$1" in
      ${pattern}|*/${pattern})
         return $YES
      ;;
   esac
   return $NO
EOF
      ;;
   esac
}


_pattern_function_header()
{
   log_entry "_pattern_function_header" "$@"

   local functionname="$1"

   echo "${functionname}()
{
${debug}
"
   if [ "${MULLE_FLAG_LOG_DEBUG}" = "YES" ]
   then
      echo "   log_entry ${functionname} \"\$@\""
   fi
}



pattern_emit_function()
{
   log_entry "pattern_emit_function" "$@"

   local functionname="$1"
   local pattern="$2"

   _pattern_function_header "${functionname}"
   pattern_emit_matchcode "${pattern}" || exit 1
   echo "}"
}


pattern_unique_functionname()
{
   log_entry "pattern_unique_functionname" "$@"

   local identifier
   local functionname

   while :
   do
      identifier="`uuidgen | tr -d '-'`"
      identifier="${identifier::10}"

      functionname="__p__${identifier}"
      if [ "`type -t "${functionname}"`" != "function" ]
      then
         echo "${functionname}"
         return
      fi
   done
}


pattern_unique_variablename()
{
   log_entry "pattern_unique_variablename" "$@"

   local identifier
   local varname

   while :
   do
      identifier="`uuidgen | tr -d '-'`"
      identifier="${identifier::10}"

      # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
      if eval [ -z \$\{__v__${identifier}+x\} ]
      then
         echo "__v__${identifier}"
         return
      fi
   done
}


#
# slow interface for testing
#
pattern_matches_relative_filename()
{
   log_entry "pattern_matches_relative_filename" "$@"

   local pattern="$1"
   local filename="$2"

   local functionname
   local declaration

   _match_assert_filename "${filename}"

   functionname="`pattern_unique_functionname`"
   declaration="`pattern_emit_function "${functionname}" "${pattern}"`"
   log_debug "define: ${declaration}"
   eval "${declaration}"
   "${functionname}" "${filename}"  # just leak
}


patternlines_match_relative_filename()
{
   log_entry "patternlines_match_relative_filename" "$@"

   local patterns="$1"
   local filename="$2"

   local pattern
   local rval

   rval=1

   IFS="
"
   set -o noglob
   for pattern in ${patterns}
   do
      IFS="${DEFAULT_IFS}"

      pattern_matches_relative_filename "${pattern}" "${filename}"
      case "$?" in
         0)
            rval=0
         ;;

         2)
            rval=1
         ;;
      esac
   done
   set +o noglob

   IFS="${DEFAULT_IFS}"

   return $rval
}


patternfile_read()
{
   log_entry "patternfile_read" "$@"

   local filename="$1"

   sed -e '/^#/d' -e '/^$/d' "${filename}"
}


patternfile_match_relative_filename()
{
   log_entry "patternfile_match_relative_filename" "$@"

   local patternfile="$1"
   local filename="$2"

   [ -z "${patternfile}" ] && internal_fail "patternfile is empty"
   [ -z "${filename}" ]    && internal_fail "filename is empty"

   lines="`patternfile_read "${patternfile}"`"

   patternlines_match_relative_filename "${lines}" "${filename}" "${patternfile}"
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
   set -o noglob
   for texpr in ${filter}
   do
      set +o noglob

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
         ${match}|*/${match})
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
   set +o noglob

   return 0
}



patternfile_identifier()
{
   log_entry "patternfile_identifier" "$@"

   local filename="$1"

   sed -e 's|.*ignore.d/\(.*\)|i_\1|' \
       -e 's|.*match.d/\(.*\)|m_\1|' <<< "${filename}" |
      tr -c '[a-zA-Z0-9_\n]' '_'
}

#
# This "compiles" the patterns into little bash functions. The functionnames
# are then put as a list into the variable <varname>.
#
# Match code will then just execute the list of functions.
#
# !!! Don't backtick this !!!
#
_patternfilefunction_create()
{
   log_entry "_patternfilefunction_create" "$@"

   local patternfile="$1"
   local varname="$2"
   local cachedirectory="$3"

   #
   # now it gets a little weird, since re-reading the patternfiles is too
   # slow we cache them in memory. The only way to do this is in global
   # variables.. Not that pretty.
   #
   local contents
   local cachefile

   if [ ! -z "${cachedirectory}" ]
   then
      cachefile="${cachedirectory}/${varname}"
      if [ "${cachefile}" -nt "${patternfile}" ]
      then
         . "${cachefile}" || internal_fail "corrupted file \"${cachefile}\""
         return 0
      fi
   fi

   contents="`patternfile_read "${patternfile}"`"
   if [ -z "${contents}" ]
   then
      log_debug "\"${patternfile}\" does not exist or is empty"
      return 1
   fi

   #
   # Compile contents into functions
   # Afterwards compile everything into one big function
   #
   local bigbody
   local functiontext
   local alltext
   local functionname
   local pattern

   # of the big function this is the start
   bigbody="
      local rval=1
"

   set -o noglob ; IFS="
"
   for pattern in ${contents}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      # build little functions for each pattern
      functionname="`pattern_unique_functionname`"
      functiontext="`pattern_emit_function "${functionname}" "${pattern}"`"

      # collect as all text
      alltext="${alltext}
${functiontext}"

      # construct call of this function in big body
      # need to deal with returnvalue of function here
      # might use ifs if this is faster
      bigbody="${bigbody}
   ${functionname} \$1
   case \"\$?\" in
      0)
         rval=0
      ;;

      2)
         rval=1
      ;;
   esac
"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   # finish up the patterfile function
   bigbody="${bigbody}
   return \${rval}
"

   functiontext="`_pattern_function_header "${varname}"`
${bigbody}
}"
   alltext="${alltext}
${functiontext}"

   #
   # we use the patternfile as the identifier, so we can cache it in memory
   #
   eval "${alltext}" || internal_fail "failed to produce functions"
   eval "${varname}_f='${patternfile}'"

   # cache it if so desired
   if [ ! -z "${cachefile}" ]
   then
      mkdir_if_missing "${cachedirectory}"
      redirect_exekutor "${cachefile}" echo "${alltext}"
   fi
}

#
# As we are setting global variables here, it is not possible to backtick
# this function. Which makes things clumsy.
#
# The cache is passed back as "_cache".
#
# TODO: cache functions in filesystem
#
# !!! Don't backtick this !!!
_patternfilefunctions_passing_filter()
{
   log_entry "_patternfilefunctions_passing_filter" "$@"

   local directory="$1"
   local filter="$2"
   local cachedirectory="$3"

   local patternfile

   # must be declared externally
   _cache=""

   shopt -s nullglob
   for patternfile in "${directory}"/[0-9]*
   do
      # be helpful...
      case "${patternfile}" in
         */[0-9]*-*--*)
         ;;

         *)
            log_warning "Ignoring badly named file \"${patternfile}\".
A valid filename is ${C_RESET_BOLD}00-type--category${C_WARNING}. \
(... minus type minus minus ...)"
            continue
         ;;
      esac

      shopt -u nullglob
      if [ ! -z "${filter}" ] && ! filter_patternfilename "${filter}" "${patternfile}"
      then
         log_debug "\"${patternfile}\" did not pass filter \"${filter}\""
         continue
      fi

      local varname

      varname="__v__`patternfile_identifier "${patternfile}"`"
      if eval [ -z \$\{${varname}+x\} ]
      then
         _patternfilefunction_create "${patternfile}" \
                                     "${varname}" \
                                     "${cachedirectory}" # will add to _cache
      fi
      _cache="`add_line "${_cache}" "${varname}"`"
   done

   shopt -u nullglob
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


matchfile_get_executable()
{
   log_entry "matchfile_get_executable" "$@"

   local filename="$1"

   sed -n -e 's/^[0-9]*-\([^-].*\)--.*/\1-did-update/p' <<< "${filename}"
}


#
# returns value in _patternfile
# don't backtick
#
_patternfilefunctions_match_relative_filename()
{
   log_entry "_patternfilefunctions_match_relative_filename" "$@"

   local patternfilefunctions="$1"
   local filename="$2"

   [ -z "${filename}" ] && internal_fail "filename is empty"

   local functionname

   set -o noglob; IFS="
"
   for functionname in ${patternfilefunctions}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      if "${functionname}" "${filename}"
      then
         _patternfile="`eval echo \$\{${functionname}_f\}`"
         log_verbose "\"${filename}\" did match \"${_patternfile}\""
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   _patternfile=""

   return 1
}


_match_assert_filename()
{
   local filename="$1"

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
}


_match_filepath()
{
   log_entry "match_filepath" "$@"

   local ignore="$1"
   local match="$2"
   local filename="$3"

   #
   # if we are strict on text input, we can simplify pattern handling
   # a lot. Note that we only deal with relative paths anyway
   #
   _match_assert_filename "${filename}"

   if [ ! -z "${ignore}" ]
   then
      if _patternfilefunctions_match_relative_filename "${ignore}" \
                                                       "${filename}"
      then
         log_debug "\"${filename}\" ignored"
         return 1
      fi
   fi

   if [ ! -z "${match}" ]
   then
      if _patternfilefunctions_match_relative_filename "${match}" \
                                                       "${filename}"
      then
         log_debug "\"${filename}\" matched"
         return 0
      fi
      log_debug "\"${filename}\" did not match"
      return 1
   fi

   #
   # nothing matches if there is no matchdir (but return special code)
   # so we can figure out if it was just ignored
   #
   return 2
}


match_filepath()
{
   log_entry "match_filepath" "$@"

   local _patternfile

   local rval

   _match_filepath "$@"
   rval="$?"
   if [ $? -ne 1 ]
   then
      echo "`fast_basename "${_patternfile}"`"
      return 0
   fi

   return 1
}


_match_print_patternfilename()
{
   log_entry "_match_print_patternfilename" "$@"

   local format="$1"
   local patternfile="$2"

   [ -z "${patternfile}" ] && internal_fail "patternfile is empty"

   local matchname

   matchname="`fast_basename "${patternfile}"`"

   local matchtype
   local matchcategory
   local matchexecutable
   local uppercase
   local s

   while [ ! -z "${format}" ]
   do
      case "${format}" in
         \%c*)
            matchcategory="`matchfile_get_category "${matchname}" `" || exit 1
            s="${s}${matchcategory}"
            format="${format:2}"
         ;;

         \%e*)
            matchexecutable="`matchfile_get_executable "${matchname}" `" || exit 1
            s="${s}${matchexecutable}"
            format="${format:2}"
         ;;

         \%f*)
            s="${s}${filename}"
            format="${format:2}"
         ;;

         \%m*)
            s="${s}${matchname}"
            format="${format:2}"
         ;;

         \%t*)
            matchtype="`matchfile_get_type "${matchname}" `" || exit 1
            s="${s}${matchtype}"
            format="${format:2}"
         ;;

         \%I*)
            matchcategory="`matchfile_get_category "${matchname}" `" || exit 1
            uppercase="`tr 'a-z' 'A-Z' <<< "${matchcategory}" | tr '-' '_' `"
            s="${s}${uppercase}"
            format="${format:2}"
         ;;

         \\n*)
            s="${s}
"
            format="${format:2}"
         ;;

         *)
            s="${s}${format:0:1}"  # optimal... :P
            format="${format:1}"
         ;;
      esac
   done

   exekutor printf "%s" "$s"
}


match_print_filepath()
{
   log_entry "match_print_filepath" "$@"

   local format="$1" ; shift
   local filename="$3" # sic

   local _patternfile

   local rval

   # avoid a backtick subshell here
   _match_filepath "$@"
   if [ $? -eq 1 ]
   then
      return 1
   fi

   _match_print_patternfilename "${format}" "${_patternfile}"
}



###
###  MAIN
###
monitor_match_main()
{
   log_entry "monitor_match_main" "$@"

   local OPTION_FORMAT="%e\\n"
   local OPTION_MATCH_FILTER
   local OPTION_IGNORE_FILTER
   local OPTION_PATTERN

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            monitor_match_usage
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

         -p|--pattern)
            [ $# -eq 1 ] && monitor_match_usage "missing argument to $1"
            shift

            OPTION_PATTERN="$1"
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

   [ "$#" -eq  0 ] && monitor_match_usage "missing filename"

   if [ ! -z "${OPTION_PATTERN}" ]
   then
      if pattern_matches_relative_filename "${OPTION_PATTERN}" "$1"
      then
         echo "match"
         return 0
      fi
      echo "no match"
      return 1
   fi

   local rval

   rval=0

   local ignore
   local match

   local _cache

   _patternfilefunctions_passing_filter "${MULLE_MONITOR_IGNORE_DIR}" \
                                         "${OPTION_IGNORE_FILTER}" \
                                         "${MULLE_MONITOR_DIR}/var/cache"
   ignore="${_cache}"

   _patternfilefunctions_passing_filter "${MULLE_MONITOR_MATCH_DIR}" \
                                        "${OPTION_MATCH_FILTER}" \
                                        "${MULLE_MONITOR_DIR}/var/cache"
   match="${_cache}"

   while [ $# -ne 0 ]
   do
      if match_print_filepath "${OPTION_FORMAT}" \
                              "${ignore}" \
                              "${match}" \
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
