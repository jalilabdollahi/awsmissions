_awsmissions_completions()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "check hint reset solution debrief status next quit help" -- "$cur") )
}
complete -F _awsmissions_completions awsmissions
