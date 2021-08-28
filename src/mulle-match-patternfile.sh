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

   A patternfile is like a .gitignore file. It consists of a list of patterns
   and comments. Each pattern is on its own line. A patternfile that matches
   all JPG and all PNG files in a "pix" folder, except all those starting with
   an underscore, could look like this:

      # commment
      pix/**/*.png
      *.jpg
      !_*

   There are patternfiles that are used to "match" files and there are
   patternfiles that are used to "ignore" files. They are kept in separate
   folders. Patternfile commands operate on "match" by default. Utilize -i to
   choose "ignore" instead.

   Each "patternfile" command comes with its own usage, that gives further
   information.
   See the Wiki for more information:
      https://github.com/mulle-sde/mulle-sde/wiki

Example:
   Show all currently installed patternfiles with their contents use:

      ${MULLE_USAGE_NAME} patternfile cat

Options:
   -i     : use ignore.d patternfiles

Commands:
   add    : add a patternfile
   cat    : show contents of patternfile
   copy   : copy a patternfile
   edit   : edit a patternfile
   ignore : create a rule to ignore a specific sourcefile
   list   : list patternfiles currently in use
   path   : print patternfile path for a given name
   remove : remove a patternfile
   rename : rename a patternfile
   repair : repair symlinks (if available)
   status : check if patternfiles need repairing
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

   Add a patternfile for a specific type. The filename of a patternfile is
   of the form <digits>-<type>--<category>. For example to crate a patternfile
   named 80-source--fooblet to match "*.fooblet" files use:

      echo "*.fooblet" | \
        ${MULLE_USAGE_NAME} patternfile add -p 80 -c fooblet source -

   If you are using mulle-match inside mulle-sde, be sure to also increase the
   filename search for *.fooblet files:

      mulle-sde environment set --add MULLE_MATCH_FILENAMES '*.fooblet'

   To create a patternfile to match C header and source files for a
   callback \"c_files\":

      (echo '*.h'; echo '*.c') | ${MULLE_USAGE_NAME} patternfile add c_files -

   See the Wiki for more information:
      https://github.com/mulle-sde/mulle-sde/wiki

Options:
   -c <name>    : give this patternfile category. The defaults are "all" or
                  "none" for match.d/ignore.d patternfiles respectively.
   -p <digits>  : position, the default is 50. Patternfiles with lower numbers
                  are matched first. (shell sort order)
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
   ${MULLE_USAGE_NAME} patternfile cat [patternfile]

   Read contents of a patternfile and print  it to stdout. You get the names of
   the available patternfiles using:

      \`${MULLE_USAGE_NAME} patternfile list\`
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
   ${MULLE_USAGE_NAME} patternfile copy [options] <srcfilename> [dstfilename]

   Copy an existing patternfile. You can also set portions of the patternfile
   with options, instead of providing a full destination patternfile name.

Options:
   -c <category>  : change the of a patternfile
   -p <digits>    : change position of the patternfile
   -t <type>      : change type of the patternfile
EOF
   exit 1
}


path_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile path [options] <filename>

   Check if a patternfile exists and if it does, output its absolute path.
   Returns 1 if no file exists.

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

   List patternfiles. A '*' indicates a file, that contains edits germane to
   the local project.

Options:
   -c                      : cat patternfile contents
   --no-output-file-marker : suppress the '*'
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

   Edit a patternfile. See the "patternfile add" command for more help.

Options:
   -a <line>        : non-interactive addition of line to file (if missing)
   -e <editor>      : specifiy editor to use instead of EDITOR (${EDITOR:-vi})
   -t <patternfile> : use patternfile as template
EOF
   exit 1
}


ignore_patternfile_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} patternfile ignore <sourcefile>

   Ignore a specific file. The file will be appended to the ignore.d
   patternfile 30-ignore--all. This is a hardcoded choice.

Options:
   -t <patternfile> : use patternfile as template for creation

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

   Repair symlinks to original patternfiles.

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
   local filemark="$2"

   if ! [ -d "${directory}" ]
   then
      return
   fi

   (
      rexekutor cd "${directory}"

      IFS=$'\n'
      for file in `rexekutor ls -1 | egrep '[0-9]*-.*--.*'`
      do
         printf "%s" "${file}"
         if [ "${filemark}" = 'YES' ] && [ ! -L "${file}" ]
         then
            printf " *"
         fi
         echo
      done
   )
}


list_patternfile_main()
{
   log_entry "list_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift
   local OPTION_CATEGORY="${1:-all}"; shift
   local OPTION_OUTPUT_FILE_MARKER="DEFAULT"

   local OPTION_DUMP='NO'

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            list_patternfile_usage
         ;;

         --no-output-file-marker|--output-no-file-marker)
            OPTION_OUTPUT_FILE_MARKER='NO'
         ;;

         --output-file-marker)
            OPTION_OUTPUT_FILE_MARKER='YES'
         ;;

         -c|--cat)
            OPTION_DUMP='YES'
         ;;

         -*)
            list_patternfile_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local directory
   local filemark='NO'

   directory="${MULLE_MATCH_USE_DIR}"
   case "${OPTION_FOLDER_NAME}" in
      ignore.d)
         directory="${MULLE_MATCH_SKIP_DIR}"
      ;;
   esac

   case "${directory}" in
      ${MULLE_MATCH_ETC_DIR}/*)
         if [ "${OPTION_OUTPUT_FILE_MARKER}" != "NO" ]
         then
            filemark='YES'
         fi
      ;;
   esac

   if [ -z "${directory}" ]
   then
      log_verbose "There is no \"${OPTION_FOLDER_NAME}\" patternfile folder setup yet"
      return 1
   fi

   local outputname
   local where
   local foldername
   local parentdir

   r_basename "${directory}"
   outputname="${RVAL}"

   r_dirname "${directory}"
   r_dirname "${RVAL}"
   parentdir="${RVAL}"

   r_basename "${parentdir}"
   where="${RVAL}"

   foldername="${OPTION_FOLDER_NAME}"

   if [ "${where}" = "etc" ]
   then
      where="${C_MAGENTA}${C_BOLD}${where}${C_INFO}"
      foldername="${C_MAGENTA}${C_BOLD}etc${C_INFO}/${foldername}"
   fi

   if [ "${OPTION_DUMP}" != 'YES' ]
   then
      log_info "${outputname%%.d} (${where}):"

      _list_patternfiles "${directory}" "${filemark}"
      return $?
   fi

   local patternfile
   local files

   files="`_list_patternfiles "${directory}"`"

   IFS=$'\n'
   for patternfile in ${files}
   do
      IFS="${DEFAULT_IFS}"
      log_info "-----------------------------------------"
      log_info "${foldername}/${patternfile}"
      log_info "-----------------------------------------"
      cat "${directory}/${patternfile}"
      echo
   done
   IFS="${DEFAULT_IFS}"
}


cat_patternfile_main()
{
   log_entry "cat_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift
   local OPTION_CATEGORY="${1:-all}"; shift

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            cat_patternfile_usage
         ;;

         -*)
            cat_patternfile_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -gt 1 ] && cat_patternfile_usage

   local filename="$1"

   if [ -z "${filename}" -o "${filename}" = '*' ]
   then
      list_patternfile_main "${OPTION_FOLDER_NAME}" "${OPTION_CATEGORY}" --cat
   else
      case "${OPTION_FOLDER_NAME}" in
         ignore.d)
            exekutor cat "${MULLE_MATCH_SKIP_DIR}/${filename}"
         ;;

         *)
            exekutor cat "${MULLE_MATCH_USE_DIR}/${filename}"
         ;;
      esac
   fi
}


remove_patternfile_main()
{
   log_entry "remove_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift
   local OPTION_CATEGORY="${1:-all}"; shift

   [ "$#" -ne 1 ] && remove_patternfile_usage

   local filename="$1"

   etc_setup_from_share_if_needed "${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}" \
                                  "${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"
   local dstfile

   dstfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${filename}"

   if [ -e "${dstfile}" ]
   then
      remove_file_if_present "${dstfile}"
   else
      fail "\"${dstfile}\" does not exist"
   fi
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


add_patternfile_main()
{
   log_entry "add_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift
   local OPTION_CATEGORY="${1:-all}"; shift

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
            add_patternfile_usage "Unknown option \"$1\""
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

   [ -e "${dstfile}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = 'NO' ] \
      && fail "\"${dstfile}\" already exists. Use -f to clobber"

   if [ "${filename}" = "-" ]
   then
      contents="`cat`"
   else
      contents="`cat "${filename}"`"
   fi

   etc_setup_from_share_if_needed "${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}" \
                                  "${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"

   etc_prepare_for_write_of_file "${dstfile}"
   redirect_exekutor "${dstfile}" printf "%s\n" "${contents}"
}


rename_patternfile_main()
{
   log_entry "rename_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift
   local OPTION_CATEGORY="$1"; shift

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
             ${usage} "Unknown option \"$1\""
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

   [ -e "${dstfile}" -a "${MULLE_FLAG_MAGNUM_FORCE}" = 'NO' ] \
      && fail "\"${dstfile}\" already exists. Use -f to clobber"


   srcfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${patternfile}"

   case "${OPTION_FOLDER_NAME}" in
      ignore.d)
         srcfile="${MULLE_MATCH_SKIP_DIR}/${patternfile}"
      ;;

      *)
         srcfile="${MULLE_MATCH_USE_DIR}/${patternfile}"
      ;;
   esac

   [ ! -f "${srcfile}" ] && fail "\"${patternfile}\" not found (at ${srcfile})"

   etc_setup_from_share_if_needed "${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}" \
                                  "${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"

   exekutor ${operation} "${srcfile}" "${dstfile}"
   exekutor chmod ug+w "${dstfile}"
}


copy_patternfile_main()
{
   log_entry "copy_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="$1"; shift
   local OPTION_CATEGORY="$1"; shift

   rename_patternfile_main "${OPTION_FOLDER_NAME}" "${OPTION_CATEGORY}" --copy "$@"
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
      fail "Source patternfile \"${srcfile}\" not found"
   fi

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' -a -f "${dstfile}" ]
   then
      fail "Patternfile \"${dstfile}\" already exists. Use -f to clobber"
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      flags="-v"
   fi

   exekutor cp ${flags} "${srcfile}" "${dstfile}" || exit 1
   exekutor chmod ug+w "${dstfile}"
}


edit_patternfile_main()
{
   log_entry "edit_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift
   local OPTION_CATEGORY="${1:-all}"; shift
   local OPTION_ADD=''

   local templatefile=""

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            edit_patternfile_usage
         ;;

         -a|--add)
            [ $# -eq 1 ] && edit_patternfile_usage "missing argument to $1"
            shift

            OPTION_ADD="$1"
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
            edit_patternfile_usage "Unknown option \"$1\""
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

   etc_setup_from_share_if_needed "${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}" \
                                  "${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"

   dstfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${filename}"

   if [ ! -z "${templatefile}" ]
   then
      copy_template_patternfile "${templatefile}" "${dstfile}"
   fi

   etc_make_file_from_symlinked_file "${dstfile}"

   if [ ! -z "${OPTION_ADD}" ]
   then
      local escaped

      r_escaped_grep_pattern "${OPTION_ADD}"
      escaped="${RVAL}"

      if ! rexekutor grep -q -x "${escaped}" "${dstfile}"
      then
         redirect_append_exekutor "${dstfile}" printf "%s\n" "${OPTION_ADD}"
      fi
   else
      exekutor "${EDITOR:-vi}" "${dstfile}"
   fi
}


ignore_patternfile_main()
{
   log_entry "ignore_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="ignore.d"; shift
   local OPTION_CATEGORY="none"; shift

   local templatefile=""

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            ignore_patternfile_usage
         ;;

         -t|--template|--template-file)
            [ $# -eq 1 ] && ignore_patternfile_usage "missing argument to $1"
            shift

            templatefile="$1"
         ;;

         -*)
            ignore_patternfile_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] && ignore_patternfile_usage

   local filename="30-ignored--none"

   local dstfile

   dstfile="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${filename}"

   etc_setup_from_share_if_needed "${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}" \
                                  "${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"

   if [ ! -z "${templatefile}" ]
   then
      copy_template_patternfile "${templatefile}" "${dstfile}"
   fi

   etc_make_file_from_symlinked_file "${dstfile}"

   merge_line_into_file "$*" "${dstfile}"
}


#
# walk through etc symlinks, cull those that point to knowwhere
# replace files with symlinks, whose content is identical to share
#
_repair_patternfile_main()
{
   log_entry "_repair_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift

   local OPTION_ADD='NO'

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            repair_patternfile_usage
         ;;

         -a|--add)
            OPTION_ADD='YES'
         ;;

         -*)
            repair_patternfile_usage "Unknown option \"$1\""
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

   [ -z "${MULLE_MATCH_SHARE_DIR}" ] && internal_fail "MULLE_MATCH_SHARE_DIR is empty"
   [ -z "${MULLE_MATCH_ETC_DIR}" ]   && internal_fail "MULLE_MATCH_ETC_DIR is empty"

   srcdir="${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"
   dstdir="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}"

   if [ ! -d "${dstdir}" ]
   then
      log_verbose "No patternfiles to repair, as \"${dstdir}\" does not exist yet"
      return
   fi

   etc_repair_files "${srcdir}" "${dstdir}" "*-" "${OPTION_ADD}"
}


repair_patternfile_main()
{
   shift
   shift

   _repair_patternfile_main "match.d" "$@" &&
   _repair_patternfile_main "ignore.d" "$@"
}


_status_patternfile_main()
{
   log_entry "_status_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift

   local OPTION_ADD='NO'

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            status_patternfile_usage
         ;;

         -*)
            status_patternfile_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 0 ] && status_patternfile_usage

   local srcdir
   local dstdir

   [ -z "${MULLE_MATCH_SHARE_DIR}" ] && internal_fail "MULLE_MATCH_SHARE_DIR is empty"
   [ -z "${MULLE_MATCH_ETC_DIR}" ]   && internal_fail "MULLE_MATCH_ETC_DIR is empty"

   srcdir="${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}"
   dstdir="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}"

   if [ ! -d "${dstdir}" ]
   then
      log_verbose "No patternfiles have been modified, as \"${dstdir}\" does not exist yet"
      return
   fi

   local filename
   local patternfile

   #
   # go through etc, throw out symlinks that point to nowhere
   # create symlinks for files that are identical in share and throw old
   # files away
   #
   shell_enable_nullglob
   for filename in "${dstdir}"/* # dstdir is etc
   do
      shell_disable_nullglob

      r_basename "${filename}"
      patternfile="${RVAL}"
      if [ -L "${filename}" ]
      then
         if ! ( cd "${dstdir}" && [ -f "`readlink "${patternfile}"`" ] )
         then
            local globtest

            globtest="*-${patternfile#*-}"
            if [ -f "${srcdir}"/${globtest} ]
            then
               log_warning "\"${patternfile}\" moved to ${globtest}, use \`patternfile repair\` to fix"
            else
               log_warning "\"${patternfile}\" no longer exists, use \`patternfile repair\` to fix"
            fi
         fi
      else
         if [ -f "${srcdir}/${patternfile}" ]
         then
            if diff -q -b "${filename}" "${srcdir}" > /dev/null
            then
               log_info "\"${patternfile}\" has no user edits, use \`patternfile repair\` to fix"
            fi
         fi
      fi
   done

   #
   # go through share, symlink everything that is not in etc
   #
   shell_enable_nullglob
   for filename in "${srcdir}"/*
   do
      shell_disable_nullglob

      r_basename "${filename}"
      patternfile="${RVAL}"
      if [ ! -e "${dstdir}/${patternfile}" ]
      then
         log_warning "\"${patternfile}\" is not used. Use \`repair --add\` to add it."
      fi
   done
   shell_disable_nullglob
}


status_patternfile_main()
{
   shift
   shift

   _status_patternfile_main "match.d" "$@"
   _status_patternfile_main "ignore.d" "$@"
}


doctor_patternfile_main()
{
   status_patternfile_main "$@"
}


path_patternfile_main()
{
   log_entry "file_patternfile_main" "$@"

   local OPTION_FOLDER_NAME="${1:-match.d}"; shift
   local OPTION_CATEGORY="$1"; shift

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            path_patternfile_usage
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

         -*)
            path_patternfile_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] && path_patternfile_usage "Missing filename"
   [ "$#" -gt 1 ] && path_patternfile_usage "Superflous arguments $*"

   local  name

   name="$1"

   if [ ! -z "${OPTION_TYPE}" ]
   then
      name="${OPTION_TYPE}"
   fi

   if [ ! -z "${OPTION_POSITION}" ]
   then
      case "${name}" in
         *[^-]-[^-]*)
         ;;

         *)
            name="${OPTION_POSITION}-${name}"
         ;;
      esac
   fi

   if [ ! -z "${OPTION_CATEGORY}" ]
   then
      case "${name}" in
         *--*)
         ;;

         *)
            name="${name}--${OPTION_CATEGORY}"
         ;;
      esac
   fi

   local share
   local etc

   [ -z "${MULLE_MATCH_SHARE_DIR}" ] && internal_fail "MULLE_MATCH_SHARE_DIR is empty"
   [ -z "${MULLE_MATCH_ETC_DIR}" ]   && internal_fail "MULLE_MATCH_ETC_DIR is empty"

   etc="${MULLE_MATCH_ETC_DIR}/${OPTION_FOLDER_NAME}/${name}"
   log_fluff "Checking ${etc}"
   if [ -f "${etc}" ]
   then
      echo "${etc}"
      return
   fi

   share="${MULLE_MATCH_SHARE_DIR}/${OPTION_FOLDER_NAME}/${name}"
   log_fluff "Checking ${share}"
   if [ -f "${share}" ]
   then
      echo "${share}"
      return
   fi

   log_info "${name} is unknown"
   return 1
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
   if [ -z "${MULLE_ETC_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-etc.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-etc.sh" || exit 1
   fi

   local OPTION_CATEGORY="all"
   local OPTION_FOLDER_NAME="match.d"
   local ONLY_IGNORE='NO'
   local ONLY_MATCH='NO'

   while :
   do
      case "$1" in
         -h*|--help|help)
            match_patternfile_usage
         ;;

         -i|--ignore-only)
            ONLY_IGNORE='YES'
            ONLY_MATCH='NO'
            OPTION_FOLDER_NAME="ignore.d"
            if [ "${OPTION_CATEGORY}" = "all" ]
            then
               OPTION_CATEGORY="none"
            fi
         ;;

         -m|--match-only)
            ONLY_IGNORE='NO'
            ONLY_MATCH='YES'
            OPTION_FOLDER_NAME="match.d"
            if [ "${OPTION_CATEGORY}" = "none" ]
            then
               OPTION_CATEGORY="all"
            fi
         ;;

         -*)
            match_patternfile_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ne 0 ] && shift

   case "${cmd:-list}" in
      add|edit|ignore|remove|repair|status)
         ${cmd}_patternfile_main "${OPTION_FOLDER_NAME}" \
                                 "${OPTION_CATEGORY}" \
                                 "$@"
      ;;

      cat|path)
         ${cmd}_patternfile_main "${OPTION_FOLDER_NAME}" \
                                 "${OPTION_CATEGORY}" \
                                 "$@"
         return $?
      ;;


      copy|rename)
         ${cmd}_patternfile_main "${OPTION_FOLDER_NAME}" \
                                 "" \
                                 "$@"
      ;;

      list)
         local delimit_cmd

         delimit_cmd="echo"
         if [ "${ONLY_MATCH}" = 'NO' ]
         then
            OPTION_FOLDER_NAME="ignore.d"
            if ! list_patternfile_main "${OPTION_FOLDER_NAME}" \
                                       "${OPTION_CATEGORY}" \
                                       "$@"
            then
               delimit_cmd=":"
            fi
         fi
         if [ "${ONLY_IGNORE}" = 'NO' ]
         then
            if [ "${ONLY_MATCH}" = 'NO' ]
            then
               ${delimit_cmd}
            fi

            OPTION_FOLDER_NAME="match.d"
            list_patternfile_main "${OPTION_FOLDER_NAME}" \
                                  "${OPTION_CATEGORY}" \
                                  "$@"
         fi
         return $?
      ;;

      "")
         match_patternfile_usage
      ;;

      *)
         match_patternfile_usage "unknown command \"${cmd}\""
      ;;
   esac


   #
   # always clean after patternfile changes
   #
   [ $? -ne 0 ] && return 1

   [ -z "${MULLE_MATCH_CLEAN_SH}" ] && \
      . "${MULLE_MATCH_LIBEXEC_DIR}/mulle-match-clean.sh"

   match_clean_main
}
