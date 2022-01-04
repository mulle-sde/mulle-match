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
MULLE_MATCH_FILENAME_SH="included"


match::filename::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} filename [options] <filename>

   Run the mulle-match file classification with the given filename. It will 
   emit the callback being matched, if there is any. You can specify an ad-hoc 
   pattern or a specific patternfile to match. This can be useful during the 
   development of your own patternfiles.

Examples:
   Which patternfile matches "foo.c" ?

      ${MULLE_USAGE_NAME} filename "foo.c"

   Will "foo.c" be matched by patternfile "95-source--sources" ?

      ${MULLE_USAGE_NAME} filename -pf 95-source--sources "foo.c"

   Is "foo.c" being matched by the pattern '*.c' ?

      ${MULLE_USAGE_NAME} filename -p '*.c' "foo.c"

Options:
   -f <patfile>  : match the filename against the specified patternfile
                   which can be either a ignore.d or a match.d patternfile
   -p <pattern>  : match the filename against the specified pattern

EOF
   exit 1
}

#
# For things that look like a directory (trailing slash) we try to do it a
# little differently. Otherwise its's pretty much just a tail match.
# the '!' is multiplied out for performance reasons
#
match::filename::assert_pattern()
{
   log_entry "match::filename::assert_pattern" "$@"

   local pattern="$1"

   case "${pattern}" in
      "")
         internal_fail "Empty pattern is illegal"
      ;;

      *"//"*)
         internal_fail "Pattern \"${pattern}\" is illegal. It must not contain  \"//\""
      ;;
   esac
}


#
# to get .gitignore like matching, where * means only a file in a directory
# and ** means match whatever (afaik) transform the pattern before
#
# ** -> *
# * -> *([^/])
#
match::filename::transform_path_pattern()
{
   log_entry "match::filename::transform_path_pattern" "$@"

   local pattern="$1"

   local prefix
   local suffix

   case "${pattern}" in
      *"/**/"*)
         prefix="`sed -e s'|\(.*\)/\*\*/\(.*\)|\1|' <<< "${pattern}"`"
         suffix="`sed -e s'|\(.*\)/\*\*/\(.*\)|\2|' <<< "${pattern}"`"
         prefix="`match::filename::transform_path_pattern "${prefix}"`"
         suffix="`match::filename::transform_path_pattern "${suffix}"`"

         log_debug "prefix: $prefix"
         log_debug "suffix: $suffix"
         printf "%s\n" "${prefix}@(/*/|/)${suffix}"
         return
      ;;

      "**/"*)
         suffix="`sed -e s'|\(.*\)\*\*\/\(.*\)|\2|' <<< "${pattern}"`"
         suffix="`match::filename::transform_path_pattern "${suffix}"`"

         log_debug "suffix: $suffix"
         printf "%s\n" "${suffix}"
         return
      ;;

      *"**"*)
         fail "Invalid pattern. ** must be followed by /"
      ;;

      *"*("*)
         # do nothing for *()
      ;;

      *"/*")
         prefix="`match::filename::transform_path_pattern "${prefix%?}"`"
         printf "%s\n" "${prefix}*([^/])"
         return
      ;;

      *"*"*)
         prefix="`sed -e s'|\(.*\)\*\(.*\)|\1|' <<< "${pattern}"`"
         suffix="`sed -e s'|\(.*\)\*\(.*\)|\2|' <<< "${pattern}"`"
         prefix="`match::filename::transform_path_pattern "${prefix}"`"
         suffix="`match::filename::transform_path_pattern "${suffix}"`"

         printf "%s\n" "${prefix}*([^/])${suffix}"
         return
      ;;
   esac

   printf "%s\n" "${pattern}"
}



match::filename::print_case_expression()
{
   log_entry "match::filename::print_case_expression" "$@"

   local pattern="$1"

   case "${pattern}" in
      "/"*"/")
         # support older bashes
         local snip

         snip="${pattern:1}"
         snip="${snip%?}"

         echo "      ${snip}|${pattern:1}*)"
      ;;

      "/"*)
         echo "      ${pattern:1})"
      ;;

      *"/")
         # echo "      ${pattern%?}|${pattern}*|*/${pattern%?}|*/${pattern}*)"
         echo "      ${pattern%?}|${pattern}*|*/${pattern}*)"
      ;;

      *"])/"*)
         echo "      ${pattern})"
      ;;

      *)
         echo "      ${pattern}|*/${pattern})"
      ;;
   esac
}




# extglob must be set
match::filename::pattern_emit_matchcode()
{
   log_entry "match::filename::pattern_emit_matchcode" "$@"

   local pattern="$1"

   local YES=0
   local NO=1

   #
   # simple invert
   #
   case "${pattern}" in
      "!!"*)
         # consider that an escape for extglob pattern
         pattern="${pattern:1}"
      ;;

      "!"*)
         pattern="${pattern:1}"
         YES=2   # negated
         NO=1    # doesn't match so we dont care
      ;;
   esac

   match::filename::assert_pattern "${pattern}"

   case "${pattern}" in
      *"*"*)
         pattern="`match::filename::transform_path_pattern "${pattern}"`"
      ;;
   esac

   echo "   case "\$1" in"

   case "${pattern}" in
      #
      # experimental code to do test after pattern matching
      #
      \[\ -?\ *\ \])
         local testchar

         testchar="${pattern:3:1}"
         pattern="${pattern:5}"
         pattern="${pattern%??}"

         match::filename::print_case_expression "${pattern}"

         cat <<EOF
         if [ -${testchar} "\$1" ]
         then
            return $YES
         fi
      ;;
   esac
   return $NO
EOF
         return
      ;;
   esac

   #
   # "normal path" outputs something like:
   # case "$1" in
   # *([^/]).c|*/*([^/]).c)
   #      return 0
   #   ;;
   #esac
   #return 1

   match::filename::print_case_expression "${pattern}"

   cat <<EOF
         return $YES
      ;;
   esac
   return $NO
EOF
}


match::filename::_pattern_function_header()
{
   log_entry "match::filename::_pattern_function_header" "$@"

   local functionname="$1"

   printf "%s\n" "${functionname}()
{"
#   if [ "${MULLE_FLAG_LOG_DEBUG}" = 'YES' -a "${MULLE_FLAG_LOG_SETTINGS}" != 'YES' ]
#   then
#      echo "   log_entry ${functionname} \"\$@\""
#   fi
}


match::filename::pattern_emit_function()
{
   log_entry "match::filename::pattern_emit_function" "$@"

   local functionname="$1"
   local pattern="$2"

   match::filename::_pattern_function_header "${functionname}"
   match::filename::pattern_emit_matchcode "${pattern}" || exit 1
   echo "}"
}


match::filename::pattern_emit_case()
{
   log_entry "match::filename::pattern_emit_case" "$@"

   local pattern="$1"

   local YES=0
   local NO=1

   #
   # simple invert
   #
   case "${pattern}" in
      "!!"*)
         # consider that an escape for extglob pattern
         pattern="${pattern:1}"
      ;;

      "!"*)
         pattern="${pattern:1}"
         YES=1   # negated
         NO=     # doesn't match so we dont care
      ;;
   esac

   match::filename::assert_pattern "${pattern}"

   case "${pattern}" in
      *"*"*)
         pattern="`match::filename::transform_path_pattern "${pattern}"`"
      ;;
   esac

   echo "   case "\$1" in"

   case "${pattern}" in
      #
      # experimental code to do test after pattern matching
      #
      \[\ -?\ *\ \])
         local testchar

         testchar="${pattern:3:1}"
         pattern="${pattern:5}"
         pattern="${pattern%??}"

         match::filename::print_case_expression "${pattern}"

         cat <<EOF
         if [ -${testchar} "\$1" ]
         then
            rval=$YES
         fi
      ;;
   esac
EOF
   esac

   #
   # "normal path" outputs something like:
   # case "$1" in
   # *([^/]).c|*/*([^/]).c)
   #      return 0
   #   ;;
   #esac
   #return 1

   match::filename::print_case_expression "${pattern}"

   cat <<EOF
         rval=$YES
      ;;
   esac
EOF
}


match::filename::r_pattern_unique_functionname()
{
   log_entry "match::filename::r_pattern_unique_functionname" "$@"

   local identifier
   local functionname

   #
   # bash uses a hash multiplying every byte, so the longer the
   # string the longer the lookup, because of it.
   #
   while :
   do
      identifier="`uuidgen | tr -d '-'`"
      identifier="${identifier:0:6}" # so

      functionname="_m${identifier}"
      # find unused name
      if ! shell_is_function "${functionname}"
      then
         RVAL="${functionname}"
         return 0
      fi
   done
}


#
# slow interface for testing
#
match::filename::pattern_matches_relative_filename()
{
   log_entry "match::filename::pattern_matches_relative_filename" "$@"

   local pattern="$1"
   local filename="$2"

   local functionname
   local declaration

   shell_enable_extglob

   match::filename::_match_assert_filename "${filename}"

   match::filename::r_pattern_unique_functionname
   functionname="${RVAL}"

   declaration="`match::filename::pattern_emit_function "${functionname}" "${pattern}"`"
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "${declaration}"
   fi

   eval "${declaration}"

   "${functionname}" "${filename}"  # just leak
}


match::filename::patternlines_match_relative_filename()
{
   log_entry "match::filename::patternlines_match_relative_filename" "$@"

   local patterns="$1"
   local filename="$2"

   local pattern
   local rval

   rval=1

   IFS=$'\n'
   shell_disable_glob
   for pattern in ${patterns}
   do
      IFS="${DEFAULT_IFS}"

      match::filename::pattern_matches_relative_filename "${pattern}" "${filename}"
      case "$?" in
         0)
            rval=0
         ;;

         2)  # 2 is correct here (not 4)
            rval=1
         ;;
      esac
   done
   shell_enable_glob

   IFS="${DEFAULT_IFS}"

   return $rval
}


match::filename::patternfile_read()
{
   log_entry "match::filename::patternfile_read" "$@"

   local filename="$1"

   if [ ! -f "${filename}" ]
   then
      if [ -L "${filename}" ]
      then
         log_verbose "\"${filename#${MULLE_USER_PWD}/}\" symbolic link is broken"
      else
         log_verbose "\"${filename#${MULLE_USER_PWD}/}\" does not exist"
      fi
      return 1
   fi

   LC_ALL=C sed -e '/^#/d' -e '/^$/d' "${filename}"
}


match::filename::patternfile_match_relative_filename()
{
   log_entry "match::filename::patternfile_match_relative_filename" "$@"

   local patternfile="$1"
   local filename="$2"

   [ -z "${patternfile}" ] && internal_fail "patternfile is empty"
   [ -z "${filename}" ]    && internal_fail "filename is empty"

   lines="`match::filename::patternfile_read "${patternfile}"`"

   match::filename::patternlines_match_relative_filename "${lines}" "${filename}" "${patternfile}"
}


match::filename::r_patternfile_identifier()
{
#   log_entry "match::filename::r_patternfile_identifier" "$@"

   local filename="$1"

   RVAL="${filename/*\/*\.d\//i_}"
   r_identifier "${RVAL}"
}

#
# This "compiles" the patterns into little bash functions. The functionnames
# are then put as a list into the variable <varname>.
#
# Match code will then just execute the list of functions.
#
# !!! Don't backtick this !!!
#
match::filename::_patternfilefunction_create()
{
   # log_entry "match::filename::_patternfilefunction_create" "$@"

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
         log_debug "Use cached \"${cachefile#${MULLE_USER_PWD}/}\" for \"${patternfile#${MULLE_USER_PWD}/}\""

         . "${cachefile}" || internal_fail "corrupted file \"${cachefile}\""
         return 0
      fi
   fi

   if ! contents="`match::filename::patternfile_read "${patternfile}"`"
   then
      log_warning "\"${patternfile#${MULLE_USER_PWD}/}\" is broken. Run \`mulle-match patternfile repair\`"
      return 1
   fi

   if [ -z "${contents}" ]
   then
      log_fluff "\"${patternfile#${MULLE_USER_PWD}/}}\" is empty"
      return 1
   fi

   #
   # Compile contents into functions
   # Afterwards compile everything into one big function
   #
   local bigbody
   local functiontext
   local alltext
#   local functionname
   local pattern

   # of the big function this is the start
   bigbody="
   local rval=1
"
   shell_disable_glob; IFS=$'\n'
   for pattern in ${contents}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      # build little cases for each pattern
#      functionname="`pattern_unique_functionname`"
      casetext="`match::filename::pattern_emit_case "${pattern}"`"

      # construct call of this function in big body
      # need to deal with returnvalue of function here
      # might use ifs if this is faster
      bigbody="${bigbody}
${casetext}"
   done

   IFS="${DEFAULT_IFS}"; shell_enable_glob

   # finish up the patternfile function
   #
   bigbody="${bigbody}
   return \${rval}"

   functiontext="`match::filename::_pattern_function_header "${varname}"`
${bigbody}
}"
   alltext="${alltext}
${functiontext}"

   #
   # we use the patternfile as the identifier, so we can cache it in memory
   #
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "${alltext}"
   fi

   eval "${alltext}" || internal_fail "failed to produce functions"

   # cache it if so desired
   if [ ! -z "${cachefile}" ]
   then
      log_fluff "Cached \"${patternfile#${MULLE_USER_PWD}/}\" in \"${cachefile#${MULLE_USER_PWD}/}\""

      mkdir_if_missing "${cachedirectory}"
      redirect_exekutor "${cachefile}" printf "%s\n" "${alltext}"
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
match::filename::_define_patternfilefunction()
{
   log_entry "match::filename::_define_patternfilefunction" "$@"

   local patternfile="$1"
   local cachedirectory="$2"

   local varname

   match::filename::r_patternfile_identifier "${patternfile}"
   varname="__p__${RVAL}"

   log_debug "Function \"${varname}\" for \"${patternfile}\""
   if eval [ -z \$\{${varname}+x\} ]
   then
      if ! match::filename::_patternfilefunction_create "${patternfile}" \
                                       "${varname}" \
                                       "${cachedirectory}" # will add to _cache
      then
         return 1
      fi
   fi

   r_add_line "${_cache}" "${varname}"
   _cache="${RVAL}"

   local varname_f

   r_basename "${patternfile}"
   varname_f="${RVAL}"

   eval "${varname}_f='${varname_f}'"

   return 0
}


match::filename::_define_patternfilefunctions()
{
   log_entry "match::filename::_define_patternfilefunctions" "$@"

   local directory="$1"
   local cachedirectory="$2"

   local patternfile

   # must be declared externally
   _cache=""

   shell_enable_nullglob
   for patternfile in "${directory}"/[0-9]*
   do
      shell_disable_nullglob

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

      match::filename::_define_patternfilefunction "${patternfile}" "${cachedirectory}"
   done

   shell_disable_nullglob
}



#
# returns value in RVAL
# don't backtick
#
# IFS must be set to LF, and noglob must be set
#
match::filename::r_patternfilefunctions_match_relative_filename()
{
   # log_entry "match::filename::r_patternfilefunctions_match_relative_filename" "${1:0:30}..." "$2"

   local patternfilefunctions="$1"
   local filename="$2"

   local functionname

   for functionname in ${patternfilefunctions}
   do
      if "${functionname}" "${filename}"
      then
         eval RVAL="\${${functionname}_f}"
         log_fluff "\"${filename}\" did match \"${RVAL}\""
         return 0
      fi
   done

   RVAL=""
   return 1
}


match::filename::_match_assert_filename()
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


#
# returns patternfile in global RVAL
#
# MUST BE CALLED WITH:
#
#      shell_enable_extglob
#      shell_disable_glob
#      IFS="
#"
match::filename::r_match_filepath()
{
   # log_entry "match::filename::r_match_filepath" "${1:0:30}..." "${2:0:30}..." "$3"

   local ignore="$1"
   local match="$2"
   local filename="$3"

   RVAL=""

   #
   # if we are strict on text input, we can simplify pattern handling
   # a lot. Note that we only deal with relative paths anyway
   #
   match::filename::_match_assert_filename "${filename}"

   if [ ! -z "${ignore}" ]
   then
      if match::filename::r_patternfilefunctions_match_relative_filename "${ignore}" "${filename}"
      then
         log_debug "\"${filename}\" ignored"
         return 1
      fi
   fi

   #
   # nothing matches if there is no matchdir (but return special code)
   # so we can figure out if it was just ignored
   #
   if [ -z "${match}" ]
   then
      return 4
   fi

   if match::filename::r_patternfilefunctions_match_relative_filename "${match}" "${filename}"
   then
      log_debug "\"${filename}\" matched"
      return 0
   fi

   log_debug "\"${filename}\" did not match"
   return 1
}


match::filename::matching_filepath_pattern()
{
   log_entry "match::filename::matching_filepath_pattern" "$@"

   local _patternfile

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

   (
      shell_enable_extglob
      shell_disable_glob

      IFS=$'\n'
      # returns 0,1,4
      match::filename::r_match_filepath "$@"
      case $? in
         0|4)
            printf "%s\n" "${RVAL##*/}"
            exit 0 # subshell
         ;;
      esac

      exit 1 # subshell
   )
}


match::filename::_match_print_patternfilename()
{
   log_entry "match::filename::_match_print_patternfilename" "$@"

   local format="$1"
   local patternfile="$2"

   [ -z "${patternfile}" ] && internal_fail "patternfile is empty"

   local matchname

   matchname="${patternfile##*/}"

   local matchtype
   local matchcategory
   local matchexecutable
   local matchdigits
   local uppercase
   local s

   while [ ! -z "${format}" ]
   do
      case "${format}" in
         \%b*)
            r_basename "${filename}"
            s="${s}${RVAL}"
            format="${format:2}"
         ;;

         \%c*)
            matchcategory="${matchname##*--}"
            s="${s}${matchcategory}"
            format="${format:2}"
         ;;

         \%d*)
            matchdigits="${matchname%%-*}"
            s="${s}${matchdigits}"
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

         \%p*)
            s="${s}${patternfile}"
            format="${format:2}"
         ;;

         \%t*)
            matchtype="${matchname%--*}"
            matchtype="${matchtype##*-}"
            s="${s}${matchtype}"
            format="${format:2}"
         ;;

         \%C*)
            matchcategory="${matchname##*--}"
            uppercase="`tr 'a-z-' 'A-Z_' <<< "${matchcategory}"`"
            s="${s}${uppercase}"
            format="${format:2}"
         ;;

         \%T*)
            matchtype="${matchname%--*}"
            matchtype="${matchtype##*-}"
            uppercase="`tr 'a-z-' 'A-Z_' <<< "${matchtype}"`"
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

   # don't use exekutor for speediness
   exekutor printf "%s" "${s}"
}


# MUST BE CALLED WITH:
#
#      shell_enable_extglob
#      shell_disable_glob
#      IFS="
#"
match::filename::_match_print_filepath()
{
   #   log_entry "match::filename::_match_print_filepath" "$@"

   local format="$1" 
   local tfilter="$2" 
   local cfilter="$3" 
   
   shift 3

#   local ignore="$1"
#   local match="$2"
   local filename="$3"

   filename="${filename#./}"

   # avoid a backtick subshell here
   # returns 0,1,2
   #
   # 2 means, no patternfiles set up
   #
   match::filename::r_match_filepath "$@"
   if [ $? -eq 1 ]
   then
      return 1
   fi

   local patternfilename
   local patternfile

   patternfile="${RVAL}"
   patternfilename="${patternfile##*/}"

   if [ ! -z "${tfilter}" ]
   then
      local matchtype

      matchtype="${patternfilename%--*}"
      matchtype="${matchtype##*-}"
      case "${matchtype}" in
         ${tfilter})
            # pass
         ;;

         *)
            return 1
         ;;
      esac
   fi

   if [ ! -z "${cfilter}" ]
   then
      local matchcategory

      matchcategory="${patternfilename#*--}"
      case "${matchcategory}" in
         ${cfilter})
            # pass
         ;;

         *)
            return 1
         ;;
      esac
   fi

   if [ -z "${format}" ]
   then
      printf "%s\n" "${filename}"
   else
      if [ "${format}" != "-" ]
      then
         if [ ! -z "${patternfile}" ]
         then
            match::filename::_match_print_patternfilename "${format}" "${patternfile}"
         fi
      fi
   fi
}


match::filename::match_check_match_filenames()
{
   local filename="$1"

   local extension
   local base 

   if [ -z "${MULLE_MATCH_FILENAMES}" ]
   then
      return 
   fi

   r_basename "${filename}"
   base="${RVAL}"

   local i 
   local matches 

   matches='NO'
   IFS=":"; shell_disable_glob
   for i in ${MULLE_MATCH_FILENAMES}
   do
      case "${base}" in 
         $i)
            matches='YES'
            break
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   if [  "${matches}" = 'NO' ]
   then
      log_warning "Does not match MULLE_MATCH_FILENAMES (${MULLE_MATCH_FILENAMES})"
   fi
}


###
###  MAIN
###
match::filename::main()
{
   log_entry "match::filename::main" "$@"

   local OPTION_FORMAT="%m\\n"
   local OPTION_MATCH_TYPE_FILTER
   local OPTION_MATCH_CATEGORY_FILTER
   local OPTION_PATTERN
   local OPTION_PATTERN_FILE

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
   while :
   do
      case "$1" in
         -h*|--help|help)
            match::filename::usage
         ;;

         -q|--quiet)
            OPTION_FORMAT='-'
         ;;
#
#         -mf|--match-filter-|-tf|--type-filter)
#            [ $# -eq 1 ] && match::filename::usage "missing argument to $1"
#            shift
#
#            OPTION_MATCH_TYPE_FILTER="$1"
#         ;;
#
#         -cf|--category-filter)
#            [ $# -eq 1 ] && match::filename::usage "missing argument to $1"
#            shift
#
#            OPTION_MATCH_CATEGORY_FILTER="$1"
#         ;;

         -p|--pattern)
            [ $# -eq 1 ] && match::filename::usage "missing argument to $1"
            shift

            OPTION_PATTERN="$1"
         ;;

         -f|-pf|--pattern-file)
            [ $# -eq 1 ] && match::filename::usage "missing argument to $1"
            shift

            OPTION_PATTERN_FILE="$1"
         ;;

         -*)
            match::filename::usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   local rval
   local filename

   [ "$#" -eq  0 ] && match::filename::usage "missing filename"
   filename="$1"
   shift

   [ "$#" -ne  0 ] && match::filename::usage "superflous arguments $*"


   match::filename::match_check_match_filenames "${filename}"

   if [ ! -z "${OPTION_PATTERN}" ]
   then
      if match::filename::pattern_matches_relative_filename "${OPTION_PATTERN}" "${filename}"
      then
         log_info "Match"
         return 0
      fi
      log_warning "No match"
      return 1
   fi


   local ignore_patterncache
   local match_patterncache
   local _cache

   if [ ! -z "${OPTION_PATTERN_FILE}" ]
   then
      if [ ! -f "${OPTION_PATTERN_FILE}" ]
      then
         if [ -f "${MULLE_MATCH_USE_DIR}/${OPTION_PATTERN_FILE}" ]
         then
            OPTION_PATTERN_FILE="${MULLE_MATCH_USE_DIR}/${OPTION_PATTERN_FILE}"
         else
            if [ -f "${MULLE_MATCH_SKIP_DIR}/${OPTION_PATTERN_FILE}" ]
            then
               OPTION_PATTERN_FILE="${MULLE_MATCH_SKIP_DIR}/${OPTION_PATTERN_FILE}"
            fi
         fi
      fi

      ignore_patterncache=""
      match::filename::_define_patternfilefunction "${OPTION_PATTERN_FILE}"
      match_patterncache="${_cache}"
   else
      [ -z "${MULLE_MATCH_VAR_DIR}" ] && internal_fail "MULLE_MATCH_VAR_DIR not set"

      match::filename::_define_patternfilefunctions "${MULLE_MATCH_SKIP_DIR}" \
                                   "${MULLE_MATCH_VAR_DIR}/cache"
      ignore_patterncache="${_cache}"

      match::filename::_define_patternfilefunctions "${MULLE_MATCH_USE_DIR}" \
                                   "${MULLE_MATCH_VAR_DIR}/cache"
      match_patterncache="${_cache}"
   fi

   local _patternfile

   match::filename::_match_print_filepath "${OPTION_FORMAT}" \
                         "${OPTION_MATCH_TYPE_FILTER}" \
                         "${OPTION_MATCH_CATEGORY_FILTER}" \
                         "${ignore_patterncache}" \
                         "${match_patterncache}" \
                         "${filename}"
   rval=$?

   if [ "${rval}" -eq 0 ]
   then
      log_info "Match"
   else
      log_warning "No match"
   fi

   return $rval
}
