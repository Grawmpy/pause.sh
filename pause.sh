declare -i TIMER isQuiet LOOP_COUNT
unset LOOP_COUNT
DEFAULT_PROMPT="Press any key to continue..."
SCRIPT="${0##*/}"
VERSION='4.0'
COPYRIGHT="Software is intended as free use and is offered 
'as is' with no implied guarantees or copyrights."
DESCRIPTION="A simple script that interrupts the current process until a key press or timer countdown finishes. 

Optional custom prompt message and countdown timer. 

Command will interrupt process indefinitely until 
  user presses any key or optional timer reaches 00. 
"

args=("$@")  # Capture all arguments in an array
for arg in "${args[@]}"; do
    case "$arg" in
        '--quiet')    OPTION_QUIET=1 ;;
        '--timer')    TIMER_SET=1 ;;
        '--prompt')   OPTION_PROMPT=1 ;;
        '--response') OPTION_RESPONSE=1 ;;
        '--help')     DISPLAY_HELP=1 ;;
        *)            OTHER_ARGS+=("$arg") ;; # Collect other args
    esac
done

while getopts "qt:p:r:h" OPTION; do
  case "$OPTION" in
    t)  TIMER="${OPTARG}"
        if ! [[ $TIMER =~ ^[0-9]+$ ]]; then
            echo "Invalid timer: must be a number"
            exit 2
        fi
        ;;
    p)  
        DEFAULT_PROMPT="${OPTARG}" ;;
    r)  
        RETURN_TEXT="${OPTARG}" ;      
        ;;
    h)  
        echo "${SCRIPT} v.${VERSION}

${COPYRIGHT}

${DESCRIPTION}

Default prompt: ${DEFAULT_PROMPT}

Usage:
${SCRIPT} [-p|--prompt ] [-t|--timer ] [-r|--response ] [-h|--help] [-q|--quiet] 

Examples:
${SCRIPT} [-p|--prompt ] [-t|--timer ] [-r|--response ] [-h|--help] [-q|--quiet] 

    -p, --prompt    [ input required (string must be in quotes) ]
    -t, --timer     [ number of seconds ]
    -r, --response  [ requires text (string must be in quotes) ]
    -h, --help      [ this information ]
    -q, --quiet     [ quiets text, requires timer be set. ]

Examples:
Input:  $ ${SCRIPT}
Output: $ ${DEFAULT_PROMPT}

Input:  $ ${SCRIPT} -t <seconds>
Output: $ [timer] ${DEFAULT_PROMPT}

Input:  $ ${SCRIPT} --prompt \"Optional Prompt\" --response \"Your response\"
Output: $ Optional Prompt
        $ Your Response

Input:  $ ${SCRIPT} -p \"Optional Prompt\" -r \"[ Your response ]\" --timer <seconds>
Output: $ [timer] Optional Prompt
        $ [ Your Response ]

[ seconds are converted to 00h:00m:00s style format ]

"  
        exit 0 
        ;;
    q ) 
        isQuiet=0 ;;
    ?)  
        echo "Help text here."
        exit 1 ;;
  esac
done

shift "$(( OPTIND - 1 ))"

format_time() {
    local COUNT="$1"
    local time_str=""

    local years=$(( COUNT / 31536000 ))
    (( years > 0 )) && time_str+="${years}y:" && COUNT=$(( COUNT % 31536000 ))

    local months=$(( COUNT / 2592000 ))
    (( months > 0 )) && time_str+="${months}m:" && COUNT=$(( COUNT % 2592000 ))

    local weeks=$(( COUNT / 604800 ))
    (( weeks > 0 )) && time_str+="${weeks}w:" && COUNT=$(( COUNT % 604800 ))

    local days=$(( COUNT / 86400 ))
    (( days > 0 )) && time_str+="${days}d:" && COUNT=$(( COUNT % 86400 ))

    local hours=$(( COUNT / 3600 ))
    (( hours > 0 )) && time_str+="${hours}h:" && COUNT=$(( COUNT % 3600 ))

    local minutes=$(( COUNT / 60 ))
    (( minutes > 0 )) && time_str+="${minutes}m:" && COUNT=$(( COUNT % 60 ))

    local seconds=$(( COUNT ))
    time_str+="${seconds}s"

    printf '%s' "$time_str"
}

quiet_countdown()  { 
    local LOOP_COUNT="$1"

    for (( LOOP_COUNT; LOOP_COUNT > 0; LOOP_COUNT-- )); do 
        printf "\e[K"  
        printf '[%s]' "$(format_time "$LOOP_COUNT")"
        printf ' %s\r' "${DEFAULT_PROMPT}"

        read -rsn1 -t1 &>/dev/null && break  # Wait for input for 1 second
    done
}

# timer interrupt
countdown_interrupt() {
    local LOOP_COUNT="$1"
    local text_prompt="$2"
    
    printf "\e[?25l"
    for (( LOOP_COUNT; LOOP_COUNT > 0; LOOP_COUNT-- )); do
        printf "\e[K"
        printf '[%s]' "$(
            COUNT="${LOOP_COUNT}"
            y=$(( COUNT / 31536000 ))
            (( y > 0 )) && printf '%02dy:' "$y"
            COUNT=$(( COUNT % 31536000 ))

            M=$(( COUNT / 2592000 ))
            (( M > 0 )) && printf '%02dm:' "$M"
            COUNT=$(( COUNT % 2592000 ))

            w=$(( COUNT / 604800 ))
            (( w > 0 )) && printf '%02dw:' "$w"
            COUNT=$(( COUNT % 604800 ))

            d=$(( COUNT / 86400 ))
            (( d > 0 )) && printf '%02dd:' "$d"
            COUNT=$(( COUNT % 86400 ))

            h=$(( COUNT / 3600 ))
            (( h > 0 )) && printf '%02dh:' "$h"
            COUNT=$(( COUNT % 3600 ))

            m=$(( COUNT / 60 ))
            (( m > 0 )) && printf '%02d:' "$m"
            COUNT=$(( COUNT % 60 ))

            s=$(( COUNT % 60 ))
            printf '%02d' "$s"
        )"
        
        printf ' %s\r' "${text_prompt}"

        read -rsn1 -t1 &>/dev/null
        if [ $? -eq 0 ]; then
            LOOP_COUNT=0  # Exit the loop if a key is pressed
        fi
    done
    printf "\e[?25h"  # Show cursor when done (optional)

}

# pause interrupt
prompt_interrupt(){ 
    local text_prompt="${1}"
    local return_prompt="${2}"
    printf '%s\n' "$(read -rsn 1 -p "${text_prompt[*]}" )"
    if [[ -n ${return_prompt} ]] ; 
        then echo -e "\n" ; printf '%s\r\n' "${return_prompt}" ; 
    fi
    return 0 
} ;

if [[ -n ${isQuiet} ]] && [[ -n ${TIMER} ]]; then
    quiet_countdown "${TIMER}" 
elif [[ -z ${isQuiet} ]] && [[ -n ${TIMER} ]]; then 
    countdown_interrupt "${TIMER}" "${DEFAULT_PROMPT}" 
    exit $? 
elif [[ -z ${isQuiet} ]] && [[ -z ${TIMER} ]]; then 
    prompt_interrupt "${DEFAULT_PROMPT}" "${RETURN_TEXT}" 
    exit $?
fi
