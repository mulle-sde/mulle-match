_mulle_match_complete() {
   COMPREPLY=()
   local cur prev words cword
   _get_comp_words_by_ref -n : cur prev words cword

   local global_options="-h --help -f -F --filename-patterns -I --ignore-path -P --path --serial --version"
   local commands="clean filename init libexec-dir list match patternfile types uname version categories"

   if [[ $cur == -* ]]; then
       COMPREPLY=($(compgen -W "$global_options" -- "$cur"))
   else
      if [ $cword -eq 1 ]; then
         COMPREPLY=($(compgen -W "$commands p*" -- "$cur"))
      else
         case "${words[1]}" in
            clean)
               COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
               ;;
            filename)
               case "$cur" in
                  -*)
                     COMPREPLY=($(compgen -W "-h --help -p --pattern -f -pf --pattern-file -q --quiet" -- "$cur"))
                     ;;
                  *)
                     case "$prev" in
                        -p|--pattern|-f|-pf|--pattern-file)
                           COMPREPLY=($(compgen -f -- "$cur"))
                           ;;
                        *)
                           COMPREPLY=()
                     esac
               esac
               ;;
            init)
               case "$cur" in
                  -*)
                     COMPREPLY=($(compgen -W "-h --help -d --directory" -- "$cur"))
                     ;;
                  *)
                     case "$prev" in
                        -d|--directory)
                           COMPREPLY=($(compgen -f -- "$cur"))
                           ;;
                        *)
                           COMPREPLY=($(compgen -d -- "$cur"))
                     esac
               esac
               ;;
            list)
               local list_options="-h --help -f --format -l -q --qualifier --no-follow --no-gitignore --gitignore --gitignore-only --gitignore-roots-only -tq --type-matches -cq --category-matches --locations --ignore-path --match-names -a --all -u --unsorted --follow --follow-symlink --no-follow --no-follow-symlink --find-option --find-flag"
               if [[ $cur == -* ]]; then
                  COMPREPLY=($(compgen -W "$list_options" -- "$cur"))
               else
                  case "$prev" in
                     -f|--format|-q|--qualifier|-tq|--type-matches|-cq|--category-matches|--locations|--ignore-path|--match-names|--find-option|--find-flag|--gitignore)
                        COMPREPLY=()
                        ;;
                     *)
                        COMPREPLY=()
                  esac
               fi
               ;;
            patternfile)
               if [ $cword -eq 2 ]; then
                  local subcommands="add cat copy edit ignore match list path remove rename repair status test test-file"
                  COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
               else
                  local pf_options="-h --help -i --ignore-only -m --match-only"
                  if [[ $cur == -* ]]; then
                     COMPREPLY=($(compgen -W "$pf_options" -- "$cur"))
                  else
                     case "${words[2]}" in
                        add)
                           local add_options="-h --help -i --ignore -t --type -c --category -p --position"
                           if [[ $cur == -* ]]; then
                              COMPREPLY=($(compgen -W "$add_options" -- "$cur"))
                           else
                              case "$prev" in
                                 -t|--type|-c|--category|-p|--position)
                                    COMPREPLY=()
                                    ;;
                                 *)
                                    COMPREPLY=($(compgen -f -- "$cur"))
                              esac
                           fi
                           ;;
                        copy)
                           local copy_options="-h --help -c --category -p --position -t --type"
                           if [[ $cur == -* ]]; then
                              COMPREPLY=($(compgen -W "$copy_options" -- "$cur"))
                           else
                              COMPREPLY=()
                           fi
                           ;;
                        edit)
                           local edit_options="-h --help -a --add -e --editor -t --template --template-file"
                           if [[ $cur == -* ]]; then
                              COMPREPLY=($(compgen -W "$edit_options" -- "$cur"))
                           else
                              case "$prev" in
                                 -a|--add|-e|--editor|-t|--template|--template-file)
                                    COMPREPLY=()
                                    ;;
                                 *)
                                    COMPREPLY=()
                              esac
                           fi
                           ;;
                        ignore)
                           local ignore_options="-h --help -t --template --template-file"
                           if [[ $cur == -* ]]; then
                              COMPREPLY=($(compgen -W "$ignore_options" -- "$cur"))
                           else
                              COMPREPLY=()
                           fi
                           ;;
                        match)
                           local match_options="-h --help -t --template --template-file"
                           if [[ $cur == -* ]]; then
                              COMPREPLY=($(compgen -W "$match_options" -- "$cur"))
                           else
                              COMPREPLY=()
                           fi
                           ;;
                        rename)
                           local rename_options="-h --help -c --category -p --position -t --type --copy"
                           if [[ $cur == -* ]]; then
                              COMPREPLY=($(compgen -W "$rename_options" -- "$cur"))
                           else
                              COMPREPLY=()
                           fi
                           ;;
                        repair)
                           COMPREPLY=($(compgen -W "-h --help --add" -- "$cur"))
                           ;;
                        status)
                           COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                           ;;
                        test-file)
                           COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                           ;;
                        test)
                           COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                           ;;
                        cat)
                           COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                           ;;
                        list)
                           COMPREPLY=($(compgen -W "-h --help --no-output-file-marker --output-file-marker -c --cat" -- "$cur"))
                           ;;
                        path)
                           COMPREPLY=($(compgen -W "-h --help -c --category -p --position -t --type -r --read -w --write" -- "$cur"))
                           ;;
                        remove)
                           COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                           ;;
                        *)
                           COMPREPLY=()
                     esac
                  fi
               fi
               ;;
            p*)
               if [ $cword -eq 1 ]; then
                  COMPREPLY=()
               fi
               ;;
            libexec-dir|uname|version)
               COMPREPLY=()
               ;;
            categories|types)
               COMPREPLY=()
               ;;
            *)
               COMPREPLY=()
         esac
      fi
   fi

   [[ ${COMPREPLY[0]} == *= ]] && compopt -o nospace
}

complete -F _mulle_match_complete mulle-match
