#! /usr/bin/bash
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#  pause.sh
#  Version: 3.1
#  Author: Grawmpy
#  Description: This script allows for the interruption of the current process until either the
#  timer reaches 00 or the user presses any key. If no timer is used, the process
#  will be stopped indefinitely until the user manually continues the process with
#  the press of any key except shift. Using the timer (in seconds only) continues 
#  the current process without user interaction. The order of the variables can be passed 
#  to the script in any order, doesn't matter, they are processed as they are read and 
#  the result is stored until applied to the final output.
#  Copyright: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
#  SOFTWARE. 
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################

# Examples of use:

# input: (no options)
# $ ./pause.sh
# output:
# $ Press any key to continue...
# $

# input: (with timer)
# $ ./pause.sh -t 10 [or, --timer 10]
# output:
# $ [10] Press any key to continue...
# $

# input: (with timer, custom prompt and custom response text)
# $ ./pause.sh --timer 10 --prompt '*Finished process 1*' --response '** Continuing with process 2 **'
#   or 
# $ ./pause.sh -t 10 -p 'Finished process 1' -r '** Continuing with process 2 **'
# output:
# $ [10] Finished process 1
# $ ** Continuing with process 2 **
# $

declare DEFAULT_PROMPT RETURN_TEXT SCRIPT VERSION COPYRIGHT DESCRIPTION arg OPTION LOOP_COUNT text_prompt return_prompt
declare -i TIMER isQuiet LOOP_COUNT
unset TIMER isQuiet DEFAULT_PROMPT RETURN_TEXT SCRIPT VERSION COPYRIGHT DESCRIPTION arg OPTION LOOP_COUNT text_prompt return_prompt
DEFAULT_PROMPT="Press any key to continue..."
SCRIPT="$(basename "$0")"
VERSION='3.1'
COPYRIGHT="Software is intended as free use and is offered 
'as is' with no implied guarantees or copyrights."
DESCRIPTION="A simple script that interrupts the current process until a key press or timer countdown finishes. 

Optional custom prompt message and countdown timer. 

Command will interrupt process indefinitely until 
  user presses any key or optional timer reaches 00. 
"
for arg in "$@"; do
  shift
  case "$arg" in
    '--quiet'    ) set -- "$@" '-q'   ;;
    '--timer'    ) set -- "$@" '-t'   ;;
    '--prompt'   ) set -- "$@" '-p'   ;;
    '--response' ) set -- "$@" '-r'   ;;
    '--help'     ) set -- "$@" '-h'   ;;
    *            ) set -- "$@" "$arg" ;;
  esac
done

while getopts "qt:p:r:h" OPTION; do
  case "$OPTION" in
    t)  TIMER="${OPTARG//^[0-9]/}"
        if [[ -z $TIMER ]] ; then echo "Timer not set" ; exit 2 ; fi
        ;;
    p)  DEFAULT_PROMPT="${OPTARG}" ;
        ;;
    r)  RETURN_TEXT="${OPTARG}" ;      
    ;;
    h)  
echo "${SCRIPT} v.${VERSION}

${COPYRIGHT}

${DESCRIPTION}

Default prompt: ${DEFAULT_PROMPT}

Usage:
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
    q ) isQuiet=0
    ;;
    ?)  
echo "${SCRIPT} v.${VERSION}
${COPYRIGHT}
${DESCRIPTION}
Usage:
${SCRIPT} [-p|--prompt ] [-t|--timer ] [-r|--response ] [-h|--help] [-q|--quiet] 

    -p, --prompt    [ input required (string must be in quotes) ]
    -t, --timer     [ number of seconds ]
    -r, --response  [ requires text (string must be in quotes) ]
    -h, --help      [ this information ]
    -q, --quiet     [ quiet text, requires timer be set. ]
"
        exit 1
        ;;
  esac
done

shift "$(( OPTIND - 1 ))"

quiet(){ 
local LOOP_COUNT="${1}"
while (( LOOP_COUNT > 0 )) ; do
    tput el
    COUNT="${LOOP_COUNT}"
    y=$(bc <<< "${COUNT}/31536000") ; COUNT=$(( COUNT % 31536000 ))
    M=$(bc <<< "${COUNT}/2592000") ; COUNT=$(( COUNT % 2592000 ))
    w=$(bc <<< "${COUNT}/604800") ; COUNT=$(( COUNT % 604800 ))
    d=$(bc <<< "${COUNT}/86400") ; COUNT=$(( COUNT % 86400 ))
    h=$(bc <<< "${COUNT}/3600") ; COUNT=$(( COUNT % 3600 ))
    m=$(bc <<< "${COUNT}/60")  ; COUNT=$(( COUNT % 60 ))
    s=$(bc <<< "${COUNT}%60"); 
    (( LOOP_COUNT = LOOP_COUNT - 1 ))
    read -rsn1 -t1 &>/dev/null 2>&1
    errorcode=$?
    [[ $errorcode -eq 0 ]] && LOOP_COUNT=0
done
}

# timer interrupt
interrupt0(){
    local LOOP_COUNT="${1}"
    local text_prompt="${2}"
    local return_prompt="${3}"
    tput civis
    while (( LOOP_COUNT > 0 )) ; do
        tput el
        printf '[%s]' "$( 
        COUNT="${LOOP_COUNT}"
        y=$(bc <<< "${COUNT}/31536000")
            if (( y > 0 )) ; 
                then 
                    printf '%02dy:' "$y" ; 
            fi ;
            COUNT=$(( COUNT % 31536000 ))
        M=$(bc <<< "${COUNT}/2592000")
                    if (( M > 0 )) ; 
                        then 
                            printf '%02dm:' "$M" ; 
                    fi ; 
            COUNT=$(( COUNT % 2592000 ))
        w=$(bc <<< "${COUNT}/604800")
                    if (( w > 0 )) ; 
                        then 
                            printf '%02dw:' "$w" ; 
                    fi ; 
            COUNT=$(( COUNT % 604800 ))
        d=$(bc <<< "${COUNT}/86400") ; 
            COUNT=$(( COUNT % 86400 ))
                if (( d > 0 )) ; 
                    then 
                        printf '%02dd:' "$d" ; 
                fi ; 

        h=$(bc <<< "${COUNT}/3600") ;  
                    if (( h > 0 )) ; 
                        then 
                            printf '%02dh:' "$h" ; 
                    fi ; 
            COUNT=$(( COUNT % 3600 ))

        m=$(bc <<< "${COUNT}/60") ; 
                    if (( m > 0 )); 
                        then 
                            printf '%02d:' "$m" ; 
                    fi ; 
            COUNT=$(( COUNT % 60 ))

        s=$(bc <<< "${COUNT}%60"); 
            if (( s >= 0 )) ; 
                then 
                    printf '%02d' "$s" ; 
            fi
    )" ; 
        printf ' %s\r' "${text_prompt}"
#        printf "[%02d] ${text_prompt[*]} \r" "${LOOP_COUNT}" >&2
        (( LOOP_COUNT = LOOP_COUNT - 1 ))
        read -rsn1 -t1 &>/dev/null 2>&1
        errorcode=$?
        [[ $errorcode -eq 0 ]] && LOOP_COUNT=0
    done 

    tput cnorm 
    
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
    local text_prompt="${1}"
    local return_prompt="${2}"
    printf '%s\n' "$(read -rsn 1 -p "${text_prompt[*]}" )"
    #tput nel
    if [[ -n ${return_prompt} ]] ; 
        then tput nel ; printf '%s\r\n' "${return_prompt}" ; 
    fi
    return 0 
} ;

if  [[ -n ${isQuiet} ]] && [[ -n ${TIMER} ]] ; 
    then quiet "${TIMER}" ; 
fi

if [[ -z ${isQuiet} ]] && [[ -n ${TIMER} ]]; 
    then 
        interrupt0 "${TIMER}" "${DEFAULT_PROMPT}" "${RETURN_TEXT}" ; 
        exit $? ; 
fi

if [[ -z ${isQuiet} ]] && [[ -z ${TIMER} ]]; 
    then interrupt1 "${DEFAULT_PROMPT}" "${RETURN_TEXT}" ; 
    exit $? ; 
fi

if [[ -z ${isQuiet} ]] && [[ -z ${TIMER} ]]; 
    then : ; 
fi
