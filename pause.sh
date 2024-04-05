#! /usr/bin/bash
# This script allow for the interruption of the current process until either the
# timer reaches 00 or the user presses any key. If no timer is used the process
# will be stopped indefinitely until the user manually continues the process with
# the press of any key except shift. Using the timer (in seconds only) continues 
# the current process without user intervention.

# Examples of use:

# input: (no options)
# $ command
# output:
# $ Press any key to continue...
# $

# input: (with timer)
# $ command -t 10 [or, --timer 10]
# output:
# $ [10] Press any key to continue...
# $

# input: (with timer, custom prompt and custom response text)
# $ command --timer 10 --prompt '*Finished process 1*' --response '** Continuing with process 2 **'
#   or 
# $ command -t 10 -p 'Finished process 1' -r '-- Continuing with process 2 --'
# output:
# $ [10] Finished process 1
# $ -- Continuing with process 2 --
# $

declare DEFAULT_PROMPT
declare -i TIMER

DEFAULT_PROMPT="Press any key to continue..."
SCRIPT="$(basename "$0")"
VERSION='2.0.1'
AUTHOR='CSPhelps'
COPYRIGHT="Software is intended as free use and is offered 
'as is' with no implied guarantees or copyrights."
DESCRIPTION="A simple script that interrupts the current process. 
Optional custom prompt message and countdown timer. 
Command will interrupt process indefinitely until 
  any key is pressed or optional timer reaches 00. 
All arguments are optional."

for arg in "$@"; do
  shift
  case "$arg" in
    '--timer'    ) set -- "$@" '-t'   ;;
    '--prompt'   ) set -- "$@" '-p'   ;;
    '--response' ) set -- "$@" '-r'   ;;
    '--help'     ) set -- "$@" '-h'   ;;
    *            ) set -- "$@" "$arg" ;;
  esac
done

while getopts ":t:p:r:h" OPTION; do
  case "$OPTION" in
    t)  TIMER="${OPTARG//^[0-9]/}"
        ;;
    p)  DEFAULT_PROMPT="${OPTARG}" ;
        ;;
    r)  RETURN_TEXT="${OPTARG}" ;      
    ;;
    h)  echo "${SCRIPT} v.${VERSION} by ${AUTHOR}
        ${COPYRIGHT}
        ${DESCRIPTION}
        Usage:
        ${SCRIPT} [-p, --prompt] [-t , --timer] [-r, --response] [-h, --help]

        All arguments are optional.
          -p, --prompt    [ custom prompt text (string must be in quotes) ]
          -t, --timer     [ countdown in seconds ]
          -r, --response  [ custom response when continuing (string must be in quotes) ]
          -h, --help      [ this information ]
        "  
        exit 0 
        ;;
    ?)  printf '\r%s\n\n' "${SCRIPT} v.${VERSION} by ${AUTHOR}"
        printf '\r%s\n\n' "${COPYRIGHT}" 
        printf '\r%s\n\n' "${DESCRIPTION}"
        printf '\r%s\n' "Usage:"
        printf '\r%s\n' " All arguments are optional.
        -p, --prompt    [ custom prompt text (string must be in quotes) ]
        -t, --timer     [ countdown in seconds ]
        -r, --response  [ custom response when continuing (string must be in quotes) ]
        -h, --help      [ this information ]
        "
        exit 1
        ;;
  esac
done

shift "$(( OPTIND - 1 ))"

# timer interrupt
interrupt0(){
    local loop_count="${TIMER}"
    local text_prompt="${DEFAULT_PROMPT}"
    local return_prompt="${RETURN_TEXT}"
    tput civis
    while (( loop_count > 0 )) ; do
        printf "[%02d] ${text_prompt[*]} \r" "${loop_count}" >&2
        (( loop_count = loop_count - 1 ))
        read -rn1 -t1 &>/dev/null 2>&1
        errorcode=$?
        [[ $errorcode -eq 0 ]] && loop_count=0
    done 
    tput cnorm 
#    tput nel
    if [[ -n ${return_prompt} ]] ; 
    then 
        tput nel ; printf '%s\r\n' "${return_prompt}" ; 
    else 
        tput nel ; 
    fi
    return 0
} ;

# pause interrupt
interrupt1(){ 
    local text_prompt="${DEFAULT_PROMPT}"
    local return_prompt="${RETURN_TEXT}"
    printf '%s\n' "$(read -rsn 1 -p "${text_prompt[*]}" )"
    #tput nel
    if [[ -n ${return_prompt} ]] ; 
        then tput nel ; printf '%s\r\n' "${return_prompt}" ; 
    fi
    return 0 
} ;


if [[ "${TIMER}" -ne 0 ]] ; 
then 
    interrupt0 "${TIMER}" "${DEFAULT_PROMPT}" "${RETURN_TEXT}" ; exit $? ; 
else 
    interrupt1 "${DEFAULT_PROMPT}" "${RETURN_TEXT}" ; 
    exit $? ; 
fi