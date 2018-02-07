#! /usr/bin/env bash
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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
MULLE_MONITOR_RUN_SH="included"


monitor_run_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} run [options]

   Monitor changes in the working directory.

Options:
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
   fi
   exit 1
}


#
# watch
#
process_event()
{
   log_entry "process_event" "$@"

   local ignore="$1"
   local match="$2"
   local filepath="$3"
   local cmd="$4"

   local action
   local matchname

   # cheap
   if ! action="`file_action_of_command "${cmd}" `"
   then
      return 1
   fi

   #
   # not as cheap
   #
   if ! matchname="`match_filepath "${ignore}" "${match}" "${filepath}" `"
   then
      return 1
   fi

   local contenttype
   local category

   contenttype="`matchfile_get_type "${matchname}" `"
   category="`matchfile_get_category "${matchname}" `"


   log_fluff "Do ${action} callback \"${contenttype}\" with \"${category}\""

   run_callback "${contenttype}" "${filepath}" "${action}" "${category}"
}


file_action_of_command()
{
   log_entry "file_action_of_command" "$@"

   local cmd="$1"

   case "${cmd}" in
      *CREATE*|*MOVED_TO*|*RENAMED*)
         echo "create"
      ;;


      *DELETE*|*MOVED_FROM*)
         echo "delete"
      ;;

      # PLATFORMSPECIFIC:ISFILE is touch apparently (at least on OS X)
      *CLOSE_WRITE*|PLATFORMSPECIFIC:ISFILE|*UPDATED*|*MODIFY*)
         echo "update"
      ;;

      *)
         log_debug "\"${cmd}\" is boring"
         return 1
      ;;
   esac
}



#
# misc handling
#
is_binary_missing()
{
   if which "$1" > /dev/null 2> /dev/null
   then
      return 1
   fi
   return 0
}



check_fswatch()
{
   log_entry "check_fswatch" "$@"

   FSWATCH="${FSWATCH:-fswatch}"

   if ! is_binary_missing "${FSWATCH}"
   then
      return
   fi

   local info

   case "${MULLE_UNAME}" in
      darwin)
         info="brew install fswatch"
      ;;

      linux)
         info="sudo apt-get install inotify-tools"
      ;;

      *)
         info="You have to install
       https://emcrisostomo.github.io/fswatch/
   yourself on this platform"
      ;;
   esac

   fail "To use monitor you have to install the prerequisite \"fswatch\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_EXECUTABLE_NAME} and reenter it."
}


check_inotifywait()
{
   log_entry "check_inotifywait" "$@"

   # for testing
   INOTIFYWAIT="${INOTIFYWAIT:-inotifywait}"

   if ! is_binary_missing "${INOTIFYWAIT}"
   then
      return
   fi

   local info

   case "${MULLE_UNAME}" in
      linux)
         info="sudo apt-get install inotify-tools"
      ;;

      *)
         info="I have no idea where you can get it from."
      ;;
   esac

   fail "To use monitor you have to install the prerequisite \"inotifywait\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_EXECUTABLE_NAME} and reenter it."
}


_watch_using_fswatch()
{
   log_entry "_watch_using_fswatch" "$@"

   local ignore="$1"
   local match="$2"

   #
   # Why monitoring stops, when executing a build.
   #
   # This used to be like `fswatch | read -> craft`
   #
   # A general problem was that events are queing up during a build
   # These are filtered out eventually, but it still can be quite a
   # bit of load. Also the pipe in fswatch will fill up and then
   # block. I suspect, that then we are missing all events until the
   # pipe has been drained.
   #
   # Because the craft is run in the reading pipe, there were no
   # parallel builds.
   #
   # Since events are probably lost anyway, it shouldn't matter if we
   # turn off monitoring during a build. If this ever becomes a problem
   # we can memorize the time of the last watch. Then do a find if
   # anything interesting has changed (timestamp), and if yes run an update
   # before monitoring again.
   #
   local filepath
   local cmd
   local workingdir
   local esacped_workingdir

   workingdir="${PWD}"
   escaped_workingdir="`escaped_sed_pattern "${workingdir}/"`"

   IFS="
"
   while read line
   do
      IFS="${DEFAULT_IFS}"

      #
      # extract filepath from line and
      # make it a relative filepath
      #
      filepath="`LC_ALL=C sed -e 's/^\(.*\) \(.*\)$/\1/' \
                              -e "s/^${escaped_workingdir}//" <<< "${line}" `"

      [ -z "${filepath}" ] && internal_fail "failed to parse \"${line}\""

      cmd="`echo "${line}" | LC_ALL=C sed 's/^\(.*\) \(.*\)$/\2/' | tr '[a-z]' '[A-Z]'`"

      if ! _task="`process_event "${ignore}" "${match}" "${filepath}" "${cmd}"`"
      then
         continue
      fi

      [ -z "${_task}" ] && continue
      [ "${OPTION_PAUSE}" = "YES" ] && return 0

      eval run_task ${_task}

   done < <( "${FSWATCH}" -r -x --event-flag-separator : "." )  # bashism
   IFS="${DEFAULT_IFS}"

   return 1
}


watch_using_fswatch()
{
   log_entry "watch_using_fswatch" "$@"

   local _task

   while _watch_using_fswatch "$@"
   do
      [ -z "${_task}" ] && internal_fail "_task is empty"

      eval run_task ${_task}
   done
}


_remove_quotes()
{
   LC_ALL=C sed 's/^\"\([^"]*\)\"/\1/' <<< "${1}"
}


_extract_first_field_from_line()
{
   case "${_line}" in
      \"*)
         _field="`LC_ALL=C sed 's/^\"\([^"]*\)\",\(.*\)/\1/' <<< "${_line}" `"
         _line="` LC_ALL=C sed 's/^\"\([^"]*\)\",\(.*\)/\2/' <<< "${_line}" `"
      ;;

      *)
         _field="`LC_ALL=C sed 's/^\([^,]*\),\(.*\)/\1/' <<< "${_line}" `"
         _line="` LC_ALL=C sed 's/^\([^,]*\),\(.*\)/\2/' <<< "${_line}" `"
      ;;
   esac
}


_watch_using_inotifywait()
{
   log_entry "_watch_using_inotifywait" "$@"

   local ignore="$1"
   local match="$2"

   # see watch_using_fswatch comment
   local directory
   local filename
   local contenttype
   local cmd
   local _line
   local _field

   #
   # https://unix.stackexchange.com/questions/166546/bash-cannot-break-out-of-piped-while-read-loop-process-substitution-works
   #
   IFS="
"
   while read _line # directory cmd filename
   do
      IFS="${DEFAULT_IFS}"

      log_debug "${_line}"

      _extract_first_field_from_line
      directory="${_field}"
      _extract_first_field_from_line
      cmd="${_field}"
      filename="`_remove_quotes "${_line}" `"

      filepath="` filepath_concat "${directory}" "${filename}" `"

      if ! _task="`process_event "${ignore}" "${match}" "${filepath}" "${cmd}"`"
      then
         continue
      fi

      [ -z "${_task}" ] && continue
      [ "${OPTION_PAUSE}" = "YES" ] && return 0

      eval run_task ${_task}

   done < <( "${INOTIFYWAIT}" -q -r -m -c "$@" )  # bashism

   IFS="${DEFAULT_IFS}"
}


watch_using_inotifywait()
{
   log_entry "watch_using_inotifywait" "$@"

   local _task

   while _watch_using_inotifywait "$@"
   do
      [ -z "${_task}" ] && internal_fail "_task is empty"

      eval run_task ${_task}
   done
}


_cleanup_monitor()
{
   log_entry "cleanup" "$@"

   if [ -f "${MONITOR_PIDFILE}" ]
   then
      log_fluff "==> Cleanup"

      local job

      for job in `jobs -pr`
      do
         kill $job
      done

      rm "${MONITOR_PIDFILE}" 2> /dev/null
   fi

   log_fluff "==> Exit"
}


cleanup_monitor()
{
   log_entry "cleanup" "$@"

   _cleanup_monitor "$@"
   exit 1
}


prevent_superflous_monitor()
{
   log_entry "prevent_superflous_monitor" "$@"

   if check_pid "${MONITOR_PIDFILE}"
   then
      log_error "Another monitor seems to be already running in ${PROJECT_DIR}" >&2
      log_info  "If this is not the case:" >&2
      log_info  "   rm \"${MONITOR_PIDFILE}\"" >&2
      exit 1
   fi

   #
   # unconditionally remove this
   #
   if [ "${RUN_TESTS}" = "YES" ]
   then
      rm "${TEST_JOB_PIDFILE}" 2> /dev/null
   fi

   trap cleanup_monitor 2 3
   announce_pid $$ "${MONITOR_PIDFILE}"
}


###
###  MAIN
###
monitor_run_main()
{
   log_entry "monitor_run_main" "$@"

   local OPTION_IGNORE_FILTER
   local OPTION_MATCH_FILTER
   local OPTION_PAUSE="NO"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            monitor_run_usage
         ;;

         -p|--task-pauses-observation)
            OPTION_PAUSE="YES"
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

         -*)
            monitor_run_usage "unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_MONITOR_PROCESS_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-process.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-process.sh" || exit 1
   fi
   if [ -z "${MULLE_MONITOR_MATCH_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-match.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-match.sh" || exit 1
   fi
   if [ -z "${MULLE_MONITOR_CALLBACK_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-callback.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-callback.sh" || exit 1
   fi
   if [ -z "${MULLE_MONITOR_TASK_SH}" ]
   then
      # shellcheck source=src/mulle-monitor-task.sh
      . "${MULLE_MONITOR_LIBEXEC_DIR}/mulle-monitor-task.sh" || exit 1
   fi

   mkdir_if_missing "${MULLE_MONITOR_DIR}/var/run"
   MONITOR_PIDFILE="${MULLE_MONITOR_DIR}/var/run/monitor-pid"
   PROJECT_DIR="`pwd -P`"

   export MULLE_MONITOR_LIBEXEC_DIR
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_MONITOR_DIR
   export MULLE_MONITOR_ETC_DIR
   export MULLE_MONITOR_MATCH_DIR
   export MULLE_MONITOR_IGNORE_DIR

   case "${MULLE_UNAME}" in
      linux)
         check_inotifywait
      ;;

      *)
         check_fswatch
      ;;
   esac

   prevent_superflous_monitor

   log_verbose "==> Start monitoring"
   log_fluff "Edits in your directory \"${PROJECT_DIR}\" are now monitored."

   log_info "Press [CTRL]-[C] to quit"

   local _cache
   local ignore
   local match

   _patterncaches_passing_filter "${MULLE_MONITOR_IGNORE_DIR}" \
                                 "${OPTION_IGNORE_FILTER}"
   ignore="${_cache}"

   _patterncaches_passing_filter "${MULLE_MONITOR_MATCH_DIR}" \
                                 "${OPTION_MATCH_FILTER}"
   match="${_cache}"

   case "${MULLE_UNAME}" in
      linux)
         watch_using_inotifywait "${ignore}" "${match}" "$@"
      ;;

      *)
         watch_using_fswatch "${ignore}" "${match}" "$@"
      ;;
   esac

   _cleanup_monitor
}
