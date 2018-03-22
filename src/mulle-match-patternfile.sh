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
   add        : add a patternfile
   cat        : show contents of patternfile
   copy       : copy a patternfile
   edit       : edit a patternfile
   list       : list patternfiles currently in use
   remove     : remove a patternfile
   rename     : rename a patternfile
   repair     : repair symlinks (if available)
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


add_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile add [options] <type> <filename>

   Add a patternfile for a specific type.

   Example. Create a patternfile to match C header and source files for a
   callback \"c_files\":

      ( echo '*.h' ; echo '*.c' ) | ${MULLE_USAGE_NAME} patternfile set c_files -

Options:
   -c <name>    : give this patternfile category. The defaults are
                  "all"/"none" for match.d/ignore.d respectively.
   -p <digits>  : position, the default is 50. Patternfiles with lower numbers
                  are matched first. (shell sort order)
EOF
   exit 1
}


copy_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile rename [options] <srcfilename> [dstfilename]

   Copy an existing patternfile. You can also set portions of the patternfile
   with options, instead of providing a full destination patternfile name.

Options:
   -c <category>  : change the of a patternfile
   -p <digits>    : change position of the patternfile
   -t <type>      : change type of the patternfile
EOF
   exit 1
}


rename_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile rename [options] <srcfilename> [dstfilename]

   Rename an existing patternfile. You can also set portions of the patternfile
   with options, instead of providing a full destination patternfile name.

Options:
   -c <category>  : change the of a patternfile
   -p <digits>    : change position of the patternfile
   -t <type>      : change type of the patternfile
EOF
   exit 1
}


remove_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile remove <filename>

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


edit_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile edit [options] <filename>

   Edit a patternfiles

Options:
   -e <editor>      : specifiy editor to use instead of EDITOR (${EDITOR:-vi})
   -t <patternfile> : use patternfile as template
EOF
   exit 1
}


repair_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile repair [options]

   Repair symlinks to original patternfile. Useful after having done an
   extension upgrade to get changes, when you have custom changes.

Options:
   --add      : add new (or previously deleted) patternfiles
EOF
   exit 1
}


#
#
#
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


remove_patternfile_main()
{
   log_entry "remove_patternfile_main" "$@"

   [ "$#" -ne 1 ] && remove_patternfile_usage

   local filename="$1"

   setup_etc_if_needed "${OPTION_FOLDER_NAME}"

   local dstfile

   dstfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${filename}"

   remove_file_if_present "${dstfile}"
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

   [ -z "`tr -d '0-9A-Za-z-_' <<< "$1"`" ]
}


prepare_for_write_of_patternfile()
{
   log_entry "prepare_for_write_of_patternfile" "$@"

   local filename="$1"

   if [ -L "${filename}" ]
   then
      exekutor rm "${filename}"
   fi
}


make_file_from_symlinked_patternfile()
{
   log_entry "make_file_from_symlinked_patternfile" "$@"

   local dstfile="$1"

   if [ ! -L "${dstfile}" ]
   then
      return 1
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      flags="-v"
   fi

   local targetfile

   targetfile="`readlink "${dstfile}"`"
   exekutor rm "${dstfile}"

   if [ ! -f "${targetfile}" ]
   then
      return 1
   fi

   exekutor cp ${flags} "${targetfile}" "${dstfile}" || exit 1
   exekutor chmod ug+w "${dstfile}"
}


symlink_or_copy_patternfile()
{
   log_entry "symlink_or_copy_patternfile" "$@"

   local srcfile="$1"
   local dstdir="$2"
   local patternfile="$3"

   [ -f "${srcfile}" ] || internal_fail "\"${srcfile}\" does not exist or not a file"
   [ -d "${dstdir}" ]  || internal_fail "\"${dstdir}\" does not exist or not a directory"

   local dstfile

   if [ -z "${patternfile}" ]
   then
      dstfile="${dstdir}/"
   else
      dstfile="`filepath_concat "${dstdir}" "${patternfile}"`"

      if [ -e "${dstfile}" ]
      then
         fail "\"${dstfile}\" already exists"
      fi
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      flags="-v"
   fi

   case "${MULLE_UNAME}" in
      mingw)
         exekutor cp ${flags} "${srcfile}" "${dstfile}"
         exekutor chmod ug+w "${dstfile}"
         return $?
      ;;
   esac

   local linkrel

   linkrel="`relative_path_between "${srcfile}" "${dstdir}"`"

   exekutor ln -s ${flags} "${linkrel}" "${dstfile}"
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

   # always create etc now
   mkdir_if_missing "${MULLE_MATCH_ETC_DIR}/${folder}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      flags="-v"
   fi

   local patternfile
   local filename

   #
   # use per default symlinks and change to file on edit (makes it
   # easier to upgrade unedited files
   #
   shopt -s nullglob
   for patternfile in "${MULLE_MATCH_DIR}/share/${folder}"/*
   do
      shopt -u nullglob
      symlink_or_copy_patternfile "${patternfile}" "${MULLE_MATCH_ETC_DIR}/${folder}"
   done
   set -u nullglob
}


add_patternfile_main()
{
   log_entry "add_patternfile_main" "$@"

   local OPTION_POSITION="50"

   while :
   do
      case "$1" in
         -h*|--help|help)
            add_patternfile_usage
         ;;

         -i|--ignore-dir|--ignore)
            OPTION_FOLDER_NAME="ignore.d"
            if [ "${OPTION_CATEGORY}" = "all" ]
            then
               OPTION_CATEGORY="none"
            fi
         ;;

         -c|--category)
            [ $# -eq 1 ] && add_patternfile_usage "missing argument to $1"
            shift

            OPTION_CATEGORY="$1"
         ;;

         -p|--position)
            [ $# -eq 1 ] && add_patternfile_usage "missing argument to $1"
            shift
            OPTION_POSITION="$1"
         ;;

         -*)
            add_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done
   [ "$#" -ne 2 ] && add_patternfile_usage

   local typename="$1"
   local filename="$2"

   [ "${filename}" = "-" -o -f "${filename}" ] || fail "\"${filename}\" not found"

   _validate_digits "${OPTION_POSITION}"   || fail "position should only contain digits"
   _validate_typename "${typename}"        || fail "type should only contain a-z _ and digits"
   _validate_category "${OPTION_CATEGORY}" || fail "category should only contain a-z _- and digits"

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

   prepare_for_write_of_patternfile "${dstfile}"
   redirect_exekutor "${dstfile}" echo "${contents}"
}


rename_patternfile_main()
{
   log_entry "rename_patternfile_main" "$@"

   local OPTION_CATEGORY
   local OPTION_POSITION
   local OPTION_TYPE
   local operation

   local usage="rename_patternfile_usage"

   operation="mv"

   while :
   do
      case "$1" in
         -h*|--help|help)
            ${usage}
         ;;

         -i|--ignore-dir|--ignore)
            OPTION_FOLDER_NAME="ignore.d"
            if [ "${OPTION_CATEGORY}" = "all" ]
            then
               OPTION_CATEGORY="none"
            fi
         ;;

         -c|--category)
            [ $# -eq 1 ] && "${usage}" "missing argument to $1"
            shift

            OPTION_CATEGORY="$1"
         ;;

         -p|--position)
            [ $# -eq 1 ] &&  ${usage} "missing argument to $1"
            shift

            OPTION_POSITION="$1"
         ;;

         -t|--type)
            [ $# -eq 1 ] &&  ${usage} "missing argument to $1"
            shift

            OPTION_TYPE="$1"
         ;;

         --copy)
            operation="cp"
            usage="copy_patternfile_usage"
         ;;

         -*)
             ${usage} "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -lt 1 -o "$#" -gt 2 ] &&  ${usage}

   local patternfile="$1"
   local dstpatternfile="$2"

   local matchposition
   local matchtype
   local matchcategory

   if [ ! -z "${dstpatternfile}" ]
   then
      matchposition="${dstpatternfile%%-*}"
      matchtype="${dstpatternfile%--*}"
      matchtype="${matchtype##*-}"
      matchcategory="${dstpatternfile##*--}"
   else
      matchposition="${patternfile%%-*}"
      matchtype="${patternfile%--*}"
      matchtype="${matchtype##*-}"
      matchcategory="${patternfile##*--}"
   fi

   matchposition="${OPTION_POSITION:-${matchposition}}"
   matchtype="${OPTION_TYPE:-${matchtype}}"
   matchcategory="${OPTION_CATEGORY:-${matchcategory}}"

   _validate_digits "${matchposition}"   || fail "position should only contain digits"
   _validate_typename "${matchtype}"     || fail "type should only contain a-z and digits"
   _validate_category "${matchcategory}" || fail "category should only contain a-z and digits"

   local dstfile
   local srcfile

   dstpatternfile="${matchposition}-${matchtype}--${matchcategory}"
   if [ "${dstpatternfile}" = "${patternfile}" ]
   then
      log_warning "No change in filename"
      return 0
   fi

   local srcfile

   dstfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${dstpatternfile}"

   [ -e "${dstfile}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = "NO" ] \
      && fail "\"${dstfile}\" already exists. Use -f to clobber"

   setup_etc_if_needed "${OPTION_FOLDER_NAME}"

   srcfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${patternfile}"

   case "${OPTION_FOLDER_NAME}" in
      ignore.d)
         srcfile="${MULLE_MATCH_IGNORE_DIR}/${patternfile}"
      ;;

      *)
         srcfile="${MULLE_MATCH_MATCH_DIR}/${patternfile}"
      ;;
   esac

   [ ! -f "${srcfile}" ] && fail "\"${patternfile}\" not found (at ${srcfile})"

   exekutor ${operation} "${srcfile}" "${dstfile}"
}


copy_patternfile_main()
{
   log_entry "copy_patternfile_main" "$@"

   rename_patternfile_main --copy "$@"
}


copy_template_patternfile()
{
   log_entry "copy_template_patternfile" "$@"

   local templatefile="$1"
   local dstfile="$2"

   local srcfile
   local flags

   srcfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${templatefile}"

   if [ ! -f "${srcfile}" ]
   then
      fail "Patternfile \"${templatefile}\" not found"
   fi

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" -a -f "${dstfile}" ]
   then
      fail "\"${dstfile}\" already exists. Use -f to clobber"
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      flags="-v"
   fi

   exekutor cp ${flags} "${srcfile}" "${dstfile}" || exit 1
   exekutor chmod ug+w "${dstfile}"
}


edit_patternfile_main()
{
   log_entry "edit_patternfile_main" "$@"

   local templatefile

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            edit_patternfile_usage
         ;;

         -e|--editor)
            [ $# -eq 1 ] && edit_patternfile_usage "missing argument to $1"
            shift

            EDITOR="$1"
         ;;

         -t|--template|--template-file)
            [ $# -eq 1 ] && edit_patternfile_usage "missing argument to $1"
            shift

            templatefile="$1"
         ;;

         -*)
            edit_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 1 ] && edit_patternfile_usage

   local filename="$1"

   local dstfile

   setup_etc_if_needed "${OPTION_FOLDER_NAME}"

   dstfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${filename}"

   if [ ! -z "${templatefile}" ]
   then
      copy_template_patternfile "${templatefile}" "${dstfile}"
   fi

   make_file_from_symlinked_patternfile "${dstfile}"

   exekutor "${EDITOR:-vi}" "${dstfile}"
}



#
# walk through etc symlinks, cull those that point to knowwhere
# replace files with symlinks, whose content is identical to share
#
repair_patternfile_main()
{
   log_entry "repair_patternfile_main" "$@"

   local OPTION_ADD="NO"

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            repair_patternfile_usage
         ;;

         -a|--add)
            OPTION_ADD="YES"
         ;;

         -*)
            repair_patternfile_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 0 ] && repair_patternfile_usage

   local srcdir
   local dstdir

   srcdir="${MULLE_MATCH_DIR}/share/${OPTION_FOLDER_NAME}"
   dstdir="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}"

   if [ ! -d "${dstdir}" ]
   then
      log_verbose "Nothing to do, as etc does not exist yet"#
      return
   fi

   local filename
   local patternfile

   #
   # go through etc, throw out symlinks that point to nowhere
   # create symlinks for files that are identical in share and throw old
   # files away
   #
   shopt -s nullglob
   for filename in "${dstdir}"/*
   do
      shopt -u nullglob

      patternfile="`fast_basename "${filename}"`"
      if [ -L "${filename}" ]
      then
         if ! ( cd "${dstdir}" && [ -f "`readlink "${patternfile}"`" ] )
         then
            log_verbose "\"${patternfile}\" no longer exists: remove"
            exekutor rm "${filename}"
         else
            log_fluff "\"${patternfile}\" is a healthy symlink: keep"
         fi
      else
         if [ -f "${srcdir}/${patternfile}" ]
         then
            if diff -q -b "${filename}" "${srcdir}" > /dev/null
            then
               log_verbose "\"${patternfile}\" has no user edits: replace with symlink"
               exekutor rm "${filename}"
               symlink_or_copy_patternfile "${srcdir}/${patternfile}" "${dstdir}"
            else
               log_fluff "\"${patternfile}\" contains edits: keep"
            fi
         else
            log_fluff "\"${patternfile}\" is an addition: keep"
         fi
      fi
   done

   #
   # go through share, symlink everything that is not in etc
   #
   shopt -s nullglob
   for filename in "${srcdir}"/*
   do
      shopt -u nullglob
      patternfile="`fast_basename "${filename}"`"
      if [ ! -e "${dstdir}/${patternfile}" ]
      then
         if [ "${OPTION_ADD}" = "YES" ]
         then
            log_verbose "\"${patternfile}\" is missing: recreate"
            symlink_or_copy_patternfile "${srcdir}/${patternfile}" "${dstdir}"
         else
            log_info "\"${patternfile}\" is not used. Use --add to add it."
         fi
      fi
   done
   shopt -u nullglob
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

         -i|--ignore-only)
            ONLY_IGNORE="YES"
            ONLY_MATCH="NO"
            OPTION_FOLDER_NAME="ignore.d"
            if [ "${OPTION_CATEGORY}" = "all" ]
            then
               OPTION_CATEGORY="none"
            fi
         ;;

         -m|--match-only)
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
      cat|copy|edit|add|rename|repair|remove)
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
