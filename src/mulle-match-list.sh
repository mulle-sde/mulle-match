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
MULLE_MATCH_LIST_SH='included'


match::list::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   match::list::set_match_path
   match::list::set_ignore_path

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} list [options]

   List files that match the rules contained in the patternfiles, that reside
   in "${MULLE_MATCH_USE_DIR#"${MULLE_USER_PWD}/"}" and that don't match those
   in "${MULLE_MATCH_SKIP_DIR#"${MULLE_USER_PWD}/"}".

   Only filenames that match the patterns in the environment variable
   MULLE_MATCH_FILENAMES are considered. If a patternfile contains a pattern
   for a file extension, say *.jpg and MULLE_MATCH_FILENAMES does not match
   *.jpg, the pattern will never be matched.

   MULLE_MATCH_FILENAMES is currently set to:
      "${MULLE_MATCH_FILENAMES:-*}"

   Only files and folders listed in MULLE_MATCH_PATH will be searched.

   MULLE_MATCH_PATH is currently set to:
      "${MULLE_MATCH_PATH}"

   Files and folders listed in MULLE_MATCH_IGNORE_PATH will be ignored. For
   good performance it is important to restrict the searched items as much as
   possible using these environment variables. 

   MULLE_MATCH_IGNORE_PATH is currently set to:
      "${MULLE_MATCH_IGNORE_PATH}"

Examples:
   List all files matched by patternfiles sorted by type and category:

      ${MULLE_USAGE_NAME} list -l

   List names of all matching files together with the matching patternfiles:

      ${MULLE_USAGE_NAME} list -f "%m: %b\\n"

   Search for C source files in 'src' and 'foo/src' only:

      MULLE_MATCH_FILENAMES="*.c:*.h" \\
      MULLE_MATCH_PATH="src:foo/src" \\
         ${MULLE_USAGE_NAME} list --qualifier "TYPE_MATCHES=source"

Options:
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
     cat <<EOF >&2
   -f <format>      : specify output values
                      This is like a simplified C printf format:
                          %b : basename of the file
                          %c : category of file (can be empty)
                          %f : filename that was matched
                          %m : the patternfile filename
                          %t : type of file
                          %I : category of match file as an uppercase identifier
                          \\n : a linefeed
                       (e.g. 'category=%c,type=%t\\n')
EOF
   else
     cat <<EOF >&2
   -f <format>      : specify output values (-v for detailed help)
EOF
   fi

   cat <<EOF >&2
   -l               : use a long format that shows type,category and basename
   --no-follow      : don't follow symlinks
   --gitignore      : use root .gitignore file to prune search tree
   --gitignore-only : ignore patternfiles, use .gitignore file to list only
EOF
   cat <<EOF >&2
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
     cat <<EOF >&2
   -q <qualifier>   : specify a qualifier for matching <type> or <category>
                      Qualifiers have their own little language.
                      (expr), NOT expr, expr AND|OR expr, as well as the
                      operators CATEGORY_MATCHES|TYPE_MATCHES <regex>.
                      TYPE_MATCHES works exact, wheras CATEGORY_MATCHES matches
                      parts of the category (separated by '-')
   -cq <qualifier>  : shortcut qualifier to match categories
   -tq <qualifier>  : shortcut qualifier to match types
EOF
   else
     cat <<EOF >&2
   -q <qualifier>   : qualifier to match patternfiles (-v for detailed help)
   -cq <qualifier>  : shortcut qualifier to match categories
   -tq <qualifier>  : shortcut qualifier to match types
EOF
   fi

     cat <<EOF >&2
EOF

     cat <<EOF >&2

Environment:
   MULLE_MATCH_FILENAMES      : filename wildcards, separated by ':' (*)
   MULLE_MATCH_IGNORE_PATH    : locations to ignore (addiction:kitchen:...)
   MULLE_MATCH_PATH           : locations to search for (src:...)
   MULLE_MATCH_FOLLOW_SYMLINK : follow symlinks (YES)

EOF
   exit 1
}


match::list::set_match_path()
{
   if [ -z "${MULLE_MATCH_PATH}" ]
   then
      MULLE_MATCH_PATH="src:.mulle/etc/sourcetree"
      log_setting "Default MULLE_MATCH_PATH: ${MULLE_MATCH_PATH}"
   else
      log_setting "MULLE_MATCH_PATH: ${MULLE_MATCH_PATH}"
   fi
}


match::list::set_ignore_path()
{
   #
   # MULLE_MATCH_IGNORE_PATH: These are subdirectories that get
   # ignored. This can be important for acceptable performance and easier
   # setup
   #
   if [ -z "${MULLE_MATCH_IGNORE_PATH}" ]
   then
      MULLE_MATCH_IGNORE_PATH="\
${MULLE_CRAFT_ADDICTION_DIRNAME:-addiction}:\
${MULLE_CRAFT_KITCHEN_DIRNAME:-kitchen}:\
${MULLE_CRAFT_DEPENDENCY_DIRNAME:-dependency}:\
${MULLE_SOURCETREE_STASH_DIRNAME:-stash}:\
[Bb]uild:\
tmp:\
old:\
*.old:\
.mulle:\
.git"
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_setting "Default MULLE_MATCH_IGNORE_PATH: ${MULLE_MATCH_IGNORE_PATH}"
      fi
   else
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_setting "MULLE_MATCH_IGNORE_PATH: ${MULLE_MATCH_IGNORE_PATH}"
      fi
   fi
}


# this is a nicety for scripts that run find
match::list::emit_common_directories()
{
   log_entry "match::list::emit_common_directories" "$@"

   local items="$1"
   local emitter="$2"
   local parameter="$3"

   [ -z "${emitter}" ] && _internal_fail "emitter is empty"

   local collection

   # MEMO: don't sort -u anymore, the order of the files is important later
   #       for the directory inclusion for example
   #
   collection="`sed -n -e 's|^[^;]*;\(.*\)/[^/]*\.h|\1|p' <<< "${items}" | LC_ALL=C awk '!seen[$0]++'`"

   if [ ! -z "${collection}" ]
   then
      "${emitter}" "${parameter}" "${collection}"
   fi
}


# this is a nicety for scripts that run find
match::list::emit_by_category()
{
   log_entry "match::list::emit_by_category" "$@"

   local items="$1"
   local emitter="$2"

   [ -z "${emitter}" ] && _internal_fail "emitter is empty"

   local collectname
   local collection
   local remainder

   remainder="${items}"

   while [ ! -z "${remainder}" ]
   do
      # https://stackoverflow.com/questions/1773939/how-to-use-sed-to-return-something-from-first-line-which-matches-and-quit-early
      collectname="`sed -n -e '/\(^[^;]*\).*/{s//\1/p;q;}' <<< "${remainder}" `"
      collection="`grep -E "^${collectname};" <<< "${remainder}" | cut -d ';' -f 2-`"
      "${emitter}" "${collectname}" "${collection}"

      remainder="`grep -E -v "^${collectname};" <<< "${remainder}" `"
   done

   :
}


match::list::_toplevel_files()
{
   log_entry "match::list::_toplevel_files" "$@"

   local ignore="$1"

   local filenames
   local filename

   #
   # to reduce the search tree, first do a search in root only
   # and drop all ignored stuff
   #
   local quoted_filenames
   local filename
   local _patternfile # needed for _match_filepath

   for filename in .* *
   do
      if [ "${filename}" = "." -o "${filename}" = ".." ]
      then
         continue
      fi

      _match_filepath "${ignore}" "" "${filename}"

      # 0 would be matched, but we have no match_dir
      # so fall through ignore means 4
      if [ $? -eq 4 ]
      then
         echo "'${filename}'"
      fi
   done
}


match::list::parallel_list_filtered_files()
{
   log_entry "match::list::parallel_list_filtered_files" "$@"

   local quoted_filenames="$1"
   local format="$2" 
   local qualifier="$3"
   local ignore="$4"
   local match="$5"
   local quoted_find_flags="$6"

   shift 6

   include "parallel"

   local maxjobs
   local running

   r_get_core_count
   maxjobs="${RVAL}"

   local filename_0
   local filename_1
   local filename_2
   local filename_3
   local filename_4
   local filename_5
   local filename_6
   local filename_7
   local filename_8
   local filename_9
   local filename_a
   local filename_b
   local filename_c
   local filename_d
   local filename_e
   local filename_f
   local filename_10
   local filename_11
   local filename_12
   local filename_13
   local filename_14
   local filename_15
   local filename_16
   local filename_17
   local filename_18
   local filename_19
   local filename_1a
   local filename_1b
   local filename_1c
   local filename_1d
   local filename_1e
   local filename_1f

   log_debug "Search locations: ${quoted_filenames}"

   shell_enable_extglob
   shell_disable_glob

   while IFS=$'\n' read -r filename_0
   do
      read -r filename_1
      read -r filename_2
      read -r filename_3
      read -r filename_4
      read -r filename_5
      read -r filename_6
      read -r filename_7
      read -r filename_8
      read -r filename_9
      read -r filename_a
      read -r filename_b
      read -r filename_c
      read -r filename_d
      read -r filename_e
      read -r filename_f
      read -r filename_10
      read -r filename_11
      read -r filename_12
      read -r filename_13
      read -r filename_14
      read -r filename_15
      read -r filename_16
      read -r filename_17
      read -r filename_18
      read -r filename_19
      read -r filename_1a
      read -r filename_1b
      read -r filename_1c
      read -r filename_1d
      read -r filename_1e
      read -r filename_1f

      wait_for_available_job "${maxjobs}"

      (
         match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_0}"

         [ ! -z "${filename_1}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_1}"
         [ ! -z "${filename_2}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_2}"
         [ ! -z "${filename_3}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_3}"

         [ ! -z "${filename_4}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_4}"
         [ ! -z "${filename_5}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_5}"
         [ ! -z "${filename_6}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_6}"
         [ ! -z "${filename_7}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_7}"

         [ ! -z "${filename_8}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_8}"
         [ ! -z "${filename_9}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_9}"
         [ ! -z "${filename_a}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_a}"
         [ ! -z "${filename_b}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_b}"

         [ ! -z "${filename_c}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_c}"
         [ ! -z "${filename_d}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_d}"
         [ ! -z "${filename_e}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_e}"
         [ ! -z "${filename_f}" ]  && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_f}"

         [ ! -z "${filename_10}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_10}"
         [ ! -z "${filename_11}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_11}"
         [ ! -z "${filename_12}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_12}"
         [ ! -z "${filename_13}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_13}"

         [ ! -z "${filename_14}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_14}"
         [ ! -z "${filename_15}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_15}"
         [ ! -z "${filename_16}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_16}"
         [ ! -z "${filename_17}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_17}"

         [ ! -z "${filename_18}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_18}"
         [ ! -z "${filename_19}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_19}"
         [ ! -z "${filename_1a}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_1a}"
         [ ! -z "${filename_1b}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_1b}"

         [ ! -z "${filename_1c}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_1c}"
         [ ! -z "${filename_1d}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_1d}"
         [ ! -z "${filename_1e}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_1e}"
         [ ! -z "${filename_1f}" ] && match::filename::match_print_filepath "${format}" "${qualifier}" "${ignore}" "${match}" "${filename_1f}"
      ) &

   done < <( eval_exekutor find ${flags} ${quoted_filenames} "$@" -print \
               | LC_ALL="C" rexekutor sed -e 's|^\./||g' \
               | LC_ALL="C" rexekutor sort -u )

   shell_enable_glob

   log_fluff "Waiting for jobs to finish..."
   wait
   log_fluff 'All jobs finished'
}


match::list::list_filenames()
{
   log_entry "match::list::list_filenames" "$@"

   [ $# -lt 6 ] && _internal_fail "API mismatch"

   local format="$1"
   local qualifier="$2"
   local ignore="$3"
   local match="$4"
   local quoted_find_options="$5"
   local type="$6"

   shift 6

   local name
   local ignore_dirs
   local match_files
   local match_dirs

   log_setting "MULLE_MATCH_PATH:           ${MULLE_MATCH_PATH}"
   log_setting "MULLE_MATCH_IGNORE_PATH:    ${MULLE_MATCH_IGNORE_PATH}"
   log_setting "MULLE_MATCH_FILENAMES:      ${MULLE_MATCH_FILENAMES}"
   log_setting "MULLE_MATCH_FOLLOW_SYMLINK: ${MULLE_MATCH_FOLLOW_SYMLINK}"

   #
   # MULLE_MATCH_PATH: This is where the find search starts
   #
   match::list::set_match_path

   .foreachpath name in ${MULLE_MATCH_PATH}
   .do
      if [ -e "${name}" ]
      then
         r_concat "${match_dirs}" "'${name}'"
         match_dirs="${RVAL}"
      fi
   .done

   match::list::set_ignore_path

   .foreachpath name in ${MULLE_MATCH_IGNORE_PATH}
   .do
      if [ -e "${name}" ]
      then
         r_concat "${ignore_dirs}" "-path '*/${name}/*'" " -o "
         ignore_dirs="${RVAL}"
      fi
   .done

   #
   # MULLE_MATCH_FILENAMES: Even more important for acceptable perfomance is
   # to only match interesting filenames
   #
   if [ -z "${MULLE_MATCH_FILENAMES}" ]
   then
      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_setting "Default MULLE_MATCH_FILENAMES: ${MULLE_MATCH_FILENAMES}"
      fi
   else
      .foreachpath name in ${MULLE_MATCH_FILENAMES}
      .do
         r_concat "${match_files}" "-name '$name'" " -o "
         match_files="${RVAL}"
      .done

      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_setting "MULLE_MATCH_FILENAMES: ${MULLE_MATCH_FILENAMES}"
      fi
   fi

   # use xtype to also catch symlinks to files

   local query

   case "${type}" in
      files)
         # looks stupid, but is needed if we have '-L' set and we have
         # symlinks of source files
         query='\( -xtype f -o -xtype l \)'
         case "${MULLE_UNAME}" in
            darwin|*bsd|sunos|dragonfly)
               query='\( -type f -o -type l \)'
            ;;
         esac
      ;;
   esac

   local find_flags

   if [ "${MULLE_MATCH_FOLLOW_SYMLINK}" = 'YES' ]
   then
      r_concat "${find_flags}" "-L"
      find_flags="${RVAL}"
   fi

   local li
   local ri
   local fi
   local fo

   # for zsh!

   if [ ! -z "${ignore_dirs}" ]
   then
      li="\\("
      ri="\\)"
      fi=-prune
      fo=-o
   fi

   if [ ! -z "${match_files}" ]
   then
      lp="\\("
      rp="\\)"
   fi

   local quoted_args
   local arg

   for arg in "$@"
   do
      printf -v escaped "%q" "${arg}"
      r_concat "${quoted_args}" "${arg}"
   done

   shell_disable_glob
   match::list::parallel_list_filtered_files "${match_dirs:-.}" \
                                             "${format}" \
                                             "${qualifier}" \
                                             "${ignore}" \
                                             "${match}" \
                                             "${find_flags}" \
                                             "${quoted_find_options}" \
                                             ${li} ${ignore_dirs} $ri $fi ${fo} \
                                             ${query} \
                                             ${lp} ${match_files} ${rp} \
                                             "${quoted_args}"

   shell_enable_glob
}


match::list::include()
{
   include "path"
   include "file"
   include "match::filename"
}


match_all()
{
   return 0
}

match_all_f="all"


match_git()
{
   case "$1" in
      */.git/*|.git/*|*/.git|.git)
         return 0
      ;;
   esac

   return 1
}

match_git_f="git"


#
# this is running in subshell, so we can override the various global variables
# temporarily.
#
match::list::prune_match_path_with_gitignore()
(
   local gitignore_file="$1"

   match::list::set_match_path
   match::list::set_ignore_path

   local skip_patternfilefunctions
   local use_patternfilefunctions

   match::filename::r_define_patternfilefunction "${gitignore_file}"
   skip_patternfilefunctions="${RVAL}"

   r_concat "match_git" "${skip_patternfilefunctions}"
   skip_patternfilefunctions="${RVAL}"

   use_patternfilefunctions="match_all"

   local path
   local keepers
   local initial_roots

   #
   # need to get "." or absolute $PWD from the PATH as well as PWD/x which
   # would be in the roots, split this off into two arrays
   #
   # log_debug "PWD:     ${PWD}"

   .foreachpath path in ${MULLE_MATCH_PATH}
   .do
      r_simplified_absolutepath "${path}"
      r_relative_path_between "${RVAL}" "${PWD}"
     # log_debug "relative: ${RVAL}"
     # log_debug "path:     ${path}"
      case "${RVAL}" in
         */*)
            r_colon_concat_if_missing "${keepers}" "${RVAL}"
            keepers="${RVAL}"
         ;;

         *)
            r_colon_concat_if_missing "${initial_roots}" "${RVAL}"
            initial_roots="${RVAL}"
         ;;
      esac
   .done

   MULLE_MATCH_PATH="${initial_roots}"
   MULLE_MATCH_FILENAMES=
   MULLE_MATCH_FOLLOW_SYMLINK='NO'

   r_colon_concat_if_missing "${MULLE_MATCH_IGNORE_PATH}" ".git"
   MULLE_MATCH_IGNORE_PATH="${RVAL}"

   #
   # so now we do a little optimization, we run it only for the root folder
   # then we have use the output as the new MULLE_MATCH_PATH. This way
   # we do not search .gitignored folders with find...
   #
   local roots

   roots=$(match::list::list_filenames "%f\n" \
                                       "" \
                                       "${skip_patternfilefunctions}" \
                                       "${use_patternfilefunctions}" \
                                       "-mindepth 1 -maxdepth 1" \
                                       "all")

   local line

   .foreachline line in ${roots}
   .do
      r_colon_concat_if_missing "${keepers}" "${line}"
      keepers="${RVAL}"
   .done

   log_setting
   if [ -z "${keepers}" ]
   then
      return 1
   fi

   # MEMO: for bonus points we could now find .gitignore in the tree and
   #       prepend the relative path to the contained rules. We'd need to
   #       push this path to match::filename::r_define_patternfilefunction
   #       and do a little rewrite there
   #
   printf "%s\n" "${keepers}"
   return 0
)

###
###  MAIN
###
match::list::main()
{
   log_entry "match::list::main" "$@"


   local OPTION_FORMAT="%f\\n"
   local OPTION_SORTED='YES'
   local OPTION_MATCH_QUALIFIER
   local OPTION_GITIGNORE='NO'
   local OPTION_FIND_FLAGS
   local OPTION_TYPE="file"

   # backwards compatibility

   MULLE_MATCH_PATH="${MULLE_MATCH_PATH:-${MULLE_MATCH_FIND_LOCATIONS}}"
   MULLE_MATCH_IGNORE_PATH="${MULLE_MATCH_IGNORE_PATH:-${MULLE_MATCH_FIND_IGNORE_PATH}}"
   MULLE_MATCH_FOLLOW_SYMLINK="${MULLE_MATCH_FOLLOW_SYMLINK:-YES}"

   match::list::include

   local escaped

   #
   # handle options
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            match::list::usage
         ;;

         --gitignore)
            OPTION_GITIGNORE='YES'
         ;;

         --no-gitignore)
            OPTION_GITIGNORE='NO'
         ;;

         --gitignore-only)
            OPTION_GITIGNORE='ONLY'
            OPTION_FORMAT="%f\\n"
         ;;

         -q|--qualifier)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            r_concat "${OPTION_MATCH_QUALIFIER}" "$1" " OR "
            OPTION_MATCH_QUALIFIER="${RVAL}"
         ;;

         -tq|--type-matches)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            r_concat "${OPTION_MATCH_QUALIFIER}" "TYPE_MATCHES $1" " AND "
            OPTION_MATCH_QUALIFIER="${RVAL}"
         ;;

         -cq|--category-matches)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            r_concat "${OPTION_MATCH_QUALIFIER}" "CATEGORY_MATCHES $1" " AND "
            OPTION_MATCH_QUALIFIER="${RVAL}"
         ;;

         -l)
            OPTION_FORMAT="%t/%c: %f\\n"
         ;;

         --locations)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            MULLE_MATCH_PATH="$1"
         ;;

         --ignore-path)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            MULLE_MATCH_IGNORE_PATH="$1"
         ;;

         --match-names)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            MULLE_MATCH_FILENAMES="$1"
         ;;

         -f|--format)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            OPTION_FORMAT="$1"
         ;;

         -a|--all)
            OPTION_TYPE="all"
         ;;

         -u|--unsorted)
            OPTION_SORTED='NO'
         ;;

         --follow|--follow-symlink)
            MULLE_MATCH_FOLLOW_SYMLINK='YES'
         ;;

         --no-follow|--no-follow-symlink)
            MULLE_MATCH_FOLLOW_SYMLINK='NO'
         ;;

         --find-option|--find-flag)
            [ $# -eq 1 ] && match::list::usage "missing argument to $1"
            shift

            printf -v escaped "%q" "$1"
            r_concat "${OPTION_FIND_FLAGS}" "${escaped}"
            OPTION_FIND_FLAGS="${RVAL}"
         ;;

         -*)
            match::list::usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   # [ "$#" -ne 0 ] && match::list::usage "superfluous arguments \"$*\""

   #
   # check if we have not gitignore, if we do we can update MULLE_MATCH_PATH
   if [ "${OPTION_GITIGNORE}" != 'NO' ]
   then
      if [ -f .gitignore ]
      then
         local roots

         # empty .gitignore will return 1
         if roots=$(match::list::prune_match_path_with_gitignore ".gitignore")
         then
            MULLE_MATCH_PATH="${roots}"
         fi
      else
         if [ "${OPTION_GITIGNORE}" = 'ONLY' ]
         then
            OPTION_GITIGNORE='ONLY-BUT-MISSING'
         fi
      fi
   fi

   local skip_patternfilefunctions
   local use_patternfilefunctions

   case "${OPTION_GITIGNORE}" in
      ONLY)
         log_debug "gitignore list"

         match::filename::r_define_patternfilefunction ".gitignore"
         skip_patternfilefunctions="${RVAL}"

         r_concat "match_git" "${skip_patternfilefunctions}"
         skip_patternfilefunctions="${RVAL}"

         use_patternfilefunctions="match_all"
      ;;

      ONLY-BUT-MISSING)
         log_debug "missing gitgnore, lista all"

         log_warning "There is no .gitignore file here, will match all"

         skip_patternfilefunctions=""
         use_patternfilefunctions="match_all"
      ;;

      *)
         log_debug "default list"
         [ -z "${MULLE_MATCH_VAR_DIR}" ] && _internal_fail "MULLE_MATCH_VAR_DIR not set"

         match::filename::r_define_patternfilefunctions "${MULLE_MATCH_SKIP_DIR}" \
                                                        "${MULLE_MATCH_VAR_DIR}/cache/match"
         skip_patternfilefunctions="${RVAL}"

         match::filename::r_define_patternfilefunctions "${MULLE_MATCH_USE_DIR}" \
                                                        "${MULLE_MATCH_VAR_DIR}/cache/match"
         use_patternfilefunctions="${RVAL}"
      ;;
   esac

   local rc

   if [ "${OPTION_SORTED}" = 'YES' ]
   then
      match::list::list_filenames "${OPTION_FORMAT}" \
                                  "${OPTION_MATCH_QUALIFIER}" \
                                  "${skip_patternfilefunctions}" \
                                  "${use_patternfilefunctions}" \
                                  "${OPTION_FIND_FLAGS}" \
                                  "${OPTION_TYPE}" \
                                  "$@" | LC_ALL=C sort
      rc=$?
   else
      match::list::list_filenames "${OPTION_FORMAT}" \
                                  "${OPTION_MATCH_QUALIFIER}" \
                                  "${skip_patternfilefunctions}" \
                                  "${use_patternfilefunctions}" \
                                  "${OPTION_FIND_FLAGS}" \
                                  "${OPTION_TYPE}" \
                                  "$@"
      rc=$?
   fi

   return $rc
}
