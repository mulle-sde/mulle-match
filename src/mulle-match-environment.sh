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

   if [ ! -z "${directory}" ]
   then
      MULLE_MATCH_DIR="${directory}"
   fi

   # lame but practical
   if [ -z "${MULLE_MATCH_DIR}" ]
   then
      if [ -d ".mulle-sde" ]
      then
         log_fluff "MULLE_MATCH_DIR default is .mulle-sde"
         MULLE_MATCH_DIR=".mulle-sde"
      else
         log_fluff "MULLE_MATCH_DIR default is .mulle-match"
         MULLE_MATCH_DIR=".mulle-match"
      fi
   fi

   MULLE_MATCH_ETC_DIR="${MULLE_MATCH_ETC_DIR:-${MULLE_MATCH_DIR}/etc}"

   case "${MULLE_MATCH_MATCH_DIR}" in
      NO)
         MULLE_MATCH_MATCH_DIR=""
         log_fluff "Not using \"MULLE_MATCH_MATCH_DIR\""
      ;;

      "")
         MULLE_MATCH_MATCH_DIR="${MULLE_MATCH_ETC_DIR}/match.d"
         if [ ! -d "${MULLE_MATCH_MATCH_DIR}" ]
         then
            MULLE_MATCH_MATCH_DIR="${MULLE_MATCH_DIR}/share/match.d"
         fi
         if [ ! -d "${MULLE_MATCH_MATCH_DIR}" ]
         then
            log_warning "There is no directory \"${MULLE_MATCH_MATCH_DIR}\" set up"
            MULLE_MATCH_MATCH_DIR=""
         fi
      ;;
   esac

   case "${MULLE_MATCH_IGNORE_DIR}" in
      NO)
         MULLE_MATCH_IGNORE_DIR=""
         log_fluff "Not using \"MULLE_MATCH_IGNORE_DIR\""
      ;;

      "")
         MULLE_MATCH_IGNORE_DIR="${MULLE_MATCH_ETC_DIR}/ignore.d"
         if [ ! -d "${MULLE_MATCH_IGNORE_DIR}" ]
         then
            MULLE_MATCH_IGNORE_DIR="${MULLE_MATCH_DIR}/share/ignore.d"
         fi
         if [ ! -d "${MULLE_MATCH_IGNORE_DIR}" ]
         then
            log_fluff "There is no directory \"${MULLE_MATCH_IGNORE_DIR}\" set up"
            MULLE_MATCH_IGNORE_DIR=""
         fi
      ;;
   esac

   # required!
   shopt -s extglob || internal_fail "Can't extglob"
}