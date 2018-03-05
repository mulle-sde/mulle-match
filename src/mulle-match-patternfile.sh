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
MULLE_MATCH_PATTERN_FILE_SH="included"


match_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile [options] <command>

   Operations on patternfiles. A patternfile is a list of patterns. Each
   pattern is on its own line. A pattern behaves similiar to a line in
   .gitignore.

   Use the -i flag to choose "ignore" patternfiles instead of the default
   "match" patternfiles.

   This example matches all JPG and all PNG files, except those starting with an
   underscore:

   pix/**/*.png
   *.jpg
   !_*

Options:
   -i         : use ignore.d patternfiles

Commands:
   cat        : show contents of patternfile
   list       : list patternfiles currently in use
   install    : install a patternfile
   uninstall  : remove a patternfile
EOF
   exit 1
}


cat_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile cat <patternfile>

   Read contents of a patternfile and prinz it to stdout. You get the names of
   the available patternfiles using:

      \`${MULLE_USAGE_NAME}patternfile list\`
EOF
   exit 1
}


install_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile install [options] <callback> <file>

   Install a patternfile to match files to a callback.

   Example. Create a patternfile to match C header and source files for a
   callback \"c_files\":

      ( echo '*.h' ; echo ".c" ) | \
         ${MULLE_USAGE_NAME} patternfile set c_files -

Options:
   -c <name>    : give this patternfile category. The defaults are
                  "all"/"none" for match.d/ignore.d respectively. This will be
                  passed to the callback as a parameter.
   -p <digits>  : position, the default is 50. Patternfiles with lower numbers
                  are matched first. (shell sort order)
EOF
   exit 1
}


uninstall_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile uninstall <file>

   Remove a patternfile.
EOF
   exit 1
}


list_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile list [options]

   List patternfiles.

Options:
   -c   : cat patternfile contents
EOF
   exit 1
}


_list_patternfiles()
{
   log_entry "_list_patternfiles" "$@"

   local directory="$1"

   if [ -d "${directory}" ]
   then
   (
      exekutor cd "${directory}"
      exekutor ls -1 | egrep '[0-9]*-.*--.*'
   )
   fi
}


list_patternfile_main()
{
   log_entry "list_patternfile_main" "$@"

   local OPTION_DUMP="NO"

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            list_patternfile_usage
         ;;

         -c|--cat)
            OPTION_DUMP="YES"
         ;;

         -*)
            list_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local directory

   directory="${MULLE_MATCH_MATCH_DIR}"
   case "${OPTION_FOLDER_NAME}" in
      ignore.d)
         directory="${MULLE_MATCH_IGNORE_DIR}"
      ;;
   esac

   if [ "${OPTION_DUMP}" != "YES" ]
   then
      _list_patternfiles "${directory}"
      return $?
   fi

   local patternfile

   IFS="
"
   for patternfile in `_list_patternfiles "${directory}"`
   do
      IFS="${DEFAULT_IFS}"
      log_info "-----------------------------------------"
      log_info "${OPTION_FOLDER_NAME}/${patternfile}"
      log_info "-----------------------------------------"
      cat "${directory}/${patternfile}"
      echo

   done
   IFS="${DEFAULT_IFS}"
}


cat_patternfile_main()
{
   log_entry "cat_patternfile_main" "$@"

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            cat_patternfile_usage
         ;;

         -*)
            cat_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 1 ] && cat_patternfile_usage

   local filename="$1"

   case "${OPTION_FOLDER_NAME}" in
      ignore.d)
         exekutor cat "${MULLE_MATCH_IGNORE_DIR}/${filename}"
      ;;

      *)
         exekutor cat "${MULLE_MATCH_MATCH_DIR}/${filename}"
      ;;
   esac
}


uninstall_patternfile_main()
{
   log_entry "uninstall_patternfile_main" "$@"

   [ "$#" -ne 1 ] && uninstall_patternfile_usage

   local filename="$1"

   case "${OPTION_FOLDER_NAME}" in
      ignore.d)
         remove_file_if_present "${MULLE_MATCH_IGNORE_DIR}/${filename}"
      ;;

      *)
         remove_file_if_present "${MULLE_MATCH_MATCH_DIR}/${filename}"
      ;;
   esac
}


_validate_digits()
{
   log_entry "_validate_digits" "$@"

   [ ! -z "$1" -a -z "`tr -d '0-9' <<< "$1"`" ]
}


_validate_typename()
{
   log_entry "_validate_typename" "$@"

   [ ! -z "$1" -a -z "`tr -d '0-9A-Za-z_' <<< "$1"`" ]
}


_validate_category()
{
   log_entry "_validate_category" "$@"

   [ -z "`tr -d '0-9A-Za-z_' <<< "$1"`" ]
}


setup_etc_if_needed()
{
   log_entry "setup_etc_if_needed" "$@"

   local folder="$1"

   if [ -d "${MULLE_MATCH_ETC_DIR}/${folder}" ]
   then
      log_fluff "etc folder already setup"
      return
   fi

   if [ -f "${MULLE_MATCH_DIR}/share/${folder}" ]
   then
      mkdir_if_missing "${MULLE_MATCH_ETC_DIR}"
      exekutor cp -Ra "${MULLE_MATCH_DIR}/share/${folder}" "${MULLE_MATCH_ETC_DIR}"
   else
      mkdir_if_missing "${MULLE_MATCH_ETC_DIR}/${folder}"
   fi
}


install_patternfile_main()
{
   log_entry "install_patternfile_main" "$@"

   local OPTION_POSITION="50"

   while :
   do
      case "$1" in
         -h*|--help|help)
            install_patternfile_usage
         ;;

         -i)
            OPTION_FOLDER_NAME="ignore.d"
            if [ "${OPTION_CATEGORY}" = "all" ]
            then
               OPTION_CATEGORY="none"
            fi
         ;;

         -c)
            [ $# -eq 1 ] && install_patternfile_usage "missing argument to $1"
            shift

            OPTION_CATEGORY="$1"
         ;;

         -p)
            [ $# -eq 1 ] && install_patternfile_usage "missing argument to $1"
            shift
            OPTION_POSITION="$1"
         ;;

         -*)
            install_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done
   [ "$#" -ne 2 ] && install_patternfile_usage

   local typename="$1"
   local filename="$2"

   [ "${filename}" = "-" -o -f "${filename}" ] || fail "\"${filename}\" not found"

   _validate_digits "${OPTION_POSITION}"   || fail "position should only contain digits"
   _validate_typename "${typename}"        || fail "type should only contain a-z and digits"
   _validate_category "${OPTION_CATEGORY}" || fail "category should only contain a-z and digits"

   local patternfile
   local contents
   local dstfile

   patternfile="${OPTION_POSITION}-${typename}--${OPTION_CATEGORY}"
   dstfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${patternfile}"

   [ -e "${dstfile}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = "NO" ] \
      && fail "\"${dstfile}\" already exists. Use -f to clobber"

   if [ "${filename}" = "-" ]
   then
      contents="`cat`"
   else
      contents="`cat "${filename}"`"
   fi

   setup_etc_if_needed "${OPTION_FOLDER_NAME}"

   redirect_exekutor "${dstfile}" echo "${contents}"
}



###
###  MAIN
###
match_patternfile_main()
{
   log_entry "match_patternfile_main" "$@"

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

   local OPTION_FOLDER_NAME="match.d"
   local ONLY_IGNORE="NO"
   local ONLY_MATCH="NO"
   local OPTION_CATEGORY="all"

   while :
   do
      case "$1" in
         -h*|--help|help)
            match_patternfile_usage
         ;;

         -i)
            ONLY_IGNORE="YES"
            ONLY_MATCH="NO"
            OPTION_FOLDER_NAME="ignore.d"
            if [ "${OPTION_CATEGORY}" = "all" ]
            then
               OPTION_CATEGORY="none"
            fi
         ;;

         -m)
            ONLY_IGNORE="NO"
            ONLY_MATCH="YES"
            OPTION_FOLDER_NAME="match.d"
            if [ "${OPTION_CATEGORY}" = "none" ]
            then
               OPTION_CATEGORY="all"
            fi
         ;;

         -*)
            match_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ne 0 ] && shift

   case "${cmd}" in
      cat|install|uninstall)
         ${cmd}_patternfile_main "$@"
      ;;

      list)
         if [ "${ONLY_MATCH}" = "NO" ]
         then
            log_info "Ignore patternfiles (-i):"
            OPTION_FOLDER_NAME="ignore.d"
            list_patternfile_main "$@"
         fi
         if [ "${ONLY_IGNORE}" = "NO" ]
         then
            if [ "${ONLY_MATCH}" = "NO" ]
            then
               echo
            fi

            log_info "Match patternfiles:"
            OPTION_FOLDER_NAME="match.d"
            list_patternfile_main "$@"
         fi
      ;;

      "")
         match_patternfile_usage
      ;;

      *)
         match_patternfile_usage "unknown command \"${cmd}\""
      ;;
   esac
}
