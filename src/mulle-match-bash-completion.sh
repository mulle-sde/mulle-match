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
[ "${TRACE}" = "YES" ] && set -x && : "$0" "$@"


_mulle_match_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local files
   local flags
   local i

   flags="-m"
   for i in "${COMP_WORDS[@]}"
   do
      case "$i" in
         -i|--ignore-only)
            flags="-i"
         ;;
      esac
   done

   case "$prev" in
      cat|copy|edit|rename|remove)
         files="`mulle-match -s patternfile ${flags} list`"
         COMPREPLY=( $( compgen -W "${files}" -- $cur ) )
      ;;

      patternfile)
         COMPREPLY=( $( compgen -W "add cat copy edit list \
                        remove rename repair" -- $cur ) )
         return 0
      ;;
   esac

   case "$cur" in
      [a-z]*)
         COMPREPLY=( $( compgen -W "clean find libexec-dir \
match patternfile uname" -- $cur ) )
         return 0
      ;;
   esac
}

complete -F _mulle_match_complete mulle-match

