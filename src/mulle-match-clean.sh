# shellcheck shell=bash
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

MULLE_MATCH_CLEAN_SH='included'


match::clean::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean

   Remove housekeeping files.
EOF
   exit 1
}




match::clean::doctor_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} doctor

   Check if the patternfile cache is stale and clean it if so.
EOF
   exit 1
}


match::clean::doctor()
{
   log_entry "match::clean::doctor" "$@"

   include 'path'
   include 'file'

   match::environment::set_cache_path

   if [ -z "${MULLE_MATCH_CACHE_PATH}" ] || [ ! -d "${MULLE_MATCH_CACHE_PATH}" ]
   then
      log_verbose "No cache directory found, nothing to check"
      return 0
   fi

   local patternfile
   local cachefile
   local stale='NO'

   local dir

   # derive cache varname the same way r_define_patternfilefunction does
   local varname

   for dir in "${MULLE_MATCH_USE_DIR}" "${MULLE_MATCH_SKIP_DIR}"
   do
      [ -z "${dir}" ] && continue

      shell_enable_nullglob

      for patternfile in "${dir}"/[0-9]*
      do
         shell_disable_nullglob

         [ -f "${patternfile}" ] || continue

         match::filename::r_patternfile_identifier "${patternfile}"
         cachefile="${MULLE_MATCH_CACHE_PATH}/__p__${RVAL}"

         if [ -f "${cachefile}" ] && [ "${patternfile}" -nt "${cachefile}" ]
         then
            log_warning "Stale cache entry for \"${patternfile#"${MULLE_USER_PWD}/"}\""
            stale='YES'
         fi
      done
      shell_disable_nullglob
   done

   if [ "${stale}" = 'YES' ]
   then
      log_info "Stale cache entries found, cleaning cache"
      rmdir_safer "${MULLE_MATCH_CACHE_PATH}"
   else
      log_verbose "Cache is up to date"
   fi
}


###
###  MAIN
###
match::clean::main()
{
   log_entry "match::clean::main" "$@"

   include 'path'
   include 'file'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            match::clean::usage
         ;;

         -*)
            match::clean::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_MATCH_VAR_DIR}" ] && _internal_fail "empty MULLE_MATCH_VAR_DIR"

   match::environment::set_cache_path

   #
   # why another /match ?
   # because MULLE_MATCH_DIR could be shared with other MULLE tools
   # like mulle-sde and we don't want to wipe their stuff
   #
   log_verbose "Cleaning match cache"
   rmdir_safer "${MULLE_MATCH_CACHE_PATH}"
}

