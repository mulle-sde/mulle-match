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
MULLE_MATCH_INIT_SH="included"


match::init::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} init [options]

   Initialize the current directory for ${MULLE_USAGE_NAME} file match use
   by installing some demo patternfiles.


Options:
   -d <directory>    : use directory instead of current working directory

EOF
   exit 1
}



###
###  MAIN
###
match::init::main()
{
   log_entry "match::init::main" "$@"

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
            match::init::usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && match::init::usage "missing argument to $1"
            shift

            mkdir_if_missing "${directory}" || exit 1
            cd "${directory}"
         ;;

         -*)
            match::init::usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   local rval

   [ $# -ne 0 ] && match::init::usage "superflous parameters \"$*\""

   [ -z "${MULLE_MATCH_PATTERNFILE_SH}" ] &&
      . "${MULLE_MATCH_LIBEXEC_DIR}/mulle-match-patternfile.sh" || exit 1

   #
   #
   #
   PRIVATE_HEADERS="\
*[_-]private.h
*[_-]private.inc
private.h
private.inc
"
   PUBLIC_HEADERS="\
*.h
"
   SOURCES="\
*.[cm]
"

   match::patternfile::add "" "" -c private-headers -p 50 source - <<< "${PRIVATE_HEADERS}"
   match::patternfile::add "" "" -c public-headers  -p 60 source - <<< "${PUBLIC_HEADERS}"
   match::patternfile::add "" "" -c sources         -p 70 source - <<< "${SOURCES}"

   log_info "Patternfiles set up for C/ObjC"
}

