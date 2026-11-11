_awsmissions_completions()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--reset-progress --env --stop --help" -- "$cur") )
}
complete -F _awsmissions_completions awsmissions play.sh
