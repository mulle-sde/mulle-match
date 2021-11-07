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

MULLE_MATCH_ENVIRONMENT_SH="included"


match_environment()
{
   log_entry "match_environment" "$@"

   local directory="$1"
   local cmd="$2"

   if [ -z "${directory}" ]
   then
      directory="${MULLE_VIRTUAL_ROOT}"
   fi
   if [ -z "${directory}" ]
   then
      directory="`pwd -P`"
   fi

   if [ -z "${MULLE_HOSTNAME}" ]
   then
      MULLE_HOSTNAME="`hostname -s`"
   fi

   [ -z "${MULLE_PATH_SH}" ] && \
   	. "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"

   r_absolutepath "${directory}"

   MULLE_MATCH_PROJECT_DIR="${RVAL}"

   eval `( cd "${MULLE_MATCH_PROJECT_DIR}" ; "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env match )` || exit 1

   case "${MULLE_MATCH_USE_DIR}" in
      NO)
         MULLE_MATCH_USE_DIR=""
         log_fluff "Not using \"MULLE_MATCH_USE_DIR\""
      ;;

      "")
         MULLE_MATCH_USE_DIR="${MULLE_MATCH_ETC_DIR}/match.d"
         if [ ! -d "${MULLE_MATCH_USE_DIR}" ]
         then
            MULLE_MATCH_USE_DIR="${MULLE_MATCH_SHARE_DIR}/match.d"
            if [ ! -d "${MULLE_MATCH_USE_DIR}" ]
            then
            	if [ "${cmd}" != "clean" -a "${cmd}" != "init" ]
            	then
   	            log_verbose "There are no patternfiles set up yet (in \"${MULLE_MATCH_ETC_DIR#${PWD}/}\")
See ${C_RESET_BOLD}mulle-match patternfile add -h${C_VERBOSE} for help."
   	         fi
               MULLE_MATCH_USE_DIR=""
            fi
         fi
      ;;
   esac

   case "${MULLE_MATCH_SKIP_DIR}" in
      NO)
         MULLE_MATCH_SKIP_DIR=""
         log_fluff "Not using \"MULLE_MATCH_SKIP_DIR\""
      ;;

      "")
         MULLE_MATCH_SKIP_DIR="${MULLE_MATCH_ETC_DIR}/ignore.d"
         if [ ! -d "${MULLE_MATCH_SKIP_DIR}" ]
         then
            MULLE_MATCH_SKIP_DIR="${MULLE_MATCH_SHARE_DIR}/ignore.d"
            if [ ! -d "${MULLE_MATCH_SKIP_DIR}" ]
            then
               log_fluff "There is no skip directory \"${MULLE_MATCH_SKIP_DIR#${PWD}/}\" set up"
               MULLE_MATCH_SKIP_DIR=""
            fi
         fi
      ;;
   esac

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "MULLE_MATCH_ETC_DIR     : \"${MULLE_MATCH_ETC_DIR}\""
      log_trace2 "MULLE_MATCH_PROJECT_DIR : \"${MULLE_MATCH_PROJECT_DIR}\""
      log_trace2 "MULLE_MATCH_SHARE_DIR   : \"${MULLE_MATCH_SHARE_DIR}\""
      log_trace2 "MULLE_MATCH_SKIP_DIR    : \"${MULLE_MATCH_SKIP_DIR}\""
      log_trace2 "MULLE_MATCH_USE_DIR     : \"${MULLE_MATCH_USE_DIR}\""
      log_trace2 "MULLE_MATCH_VAR_DIR     : \"${MULLE_MATCH_VAR_DIR}\""
   fi

   # required!
   shell_enable_extglob || internal_fail "Can't extglob"
}
