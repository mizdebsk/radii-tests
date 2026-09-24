#!/bin/bash
. /usr/share/bash-completion/bash_completion
# The completion path is discovered from the installed RPM.
# shellcheck source=/dev/null
. "$1"
shift

# Bash's completion interface requires these arrays.
COMP_WORDS=("$@")
COMP_CWORD=$(($# - 1))
COMP_LINE="$*"
COMP_POINT=${#COMP_LINE}
COMP_TYPE=9
function_name=$(complete -p "$1" | sed -n 's/.*-F \([^ ]*\) .*/\1/p')
[ -n "${function_name}" ] || exit 1
${function_name} || exit 1
if [ ${#COMPREPLY[@]} -gt 0 ]; then
    printf '%s\n' "${COMPREPLY[@]}"
fi
