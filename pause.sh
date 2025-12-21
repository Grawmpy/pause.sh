#!/usr/bin/env bash
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#  Script: pause.sh
#  Version: 5.0.2
#  Author: Grawmpy (CSPhelps) <grawmpy@gmail.com>
#
#  Description: This script allows for the interruption of the current process until either the
#  timer reaches 00 or the user presses any key. If no timer is used, the process
#  will be stopped indefinitely until the user manually continues the process with
#  the press of any key except shift. Using the timer (in seconds only) continues 
#  the current process without user interaction. The order of the variables can be passed 
#  to the script in any order, doesn't matter, they are processed as they are read and 
#  the result is stored until applied to the final output. I wanted a function that would stop the current process
#  and at the same time offer functionality that the pause function should have had in DOS.
#
#  Command: pause
#  Options: [-p|--prompt] [-r|--response] [-t|--timer] [-q|--quiet] [-e|--echo ] [-h|--help]
#  pause ( without any options)
#  $ Press any key to continue...
#
#  Options include: (white spaces between option and it's value are not counted, it looks for first value next to the option):
#  [--prompt, -p "TEXT"]        (Prompt text must be inside double quotes, example: pause -p "Hello World", or pause --prompt "Hello World")
#  [--response, -r "TEXT"]      (Response text must be inside double quotes, example: pause -r "Thank you. Continuing...", or pause --response "Thank you. Continuing..")
#  [--timer, -t NUMBER ]        (Must be in total seconds. Example: pause -t 30, or pause --timer 30)
#  [--quiet, -q ]               (No prompt, just cursor blink. Timer must be set for use. Example: pause -q -t 10, or pause --quiet --timer 10, or pause -qt10)
#                                   You can combine the quiet mode options, such as: pause -qt10
#  [--echo, -e ]                (Echoes the key pressed character to use inside script for passing to a variable. I explicitly send the prompt and
#                                   response echoes to the >&2 which will allow for sending the prompt and response information to either logs or terminal
#                                   depending on how you set up your script. Using simple command substitution the key pressed is echoed in order to
#                                   in order to be useful in case statements or other areas where a single key press needs to be used. )
#
#  Copyright (C) 2025 Grawmpy (CSPhelps) <grawmpy@gmail.com>
#  This software is licensed under the GNU General Public License (GPL) version 3.0 only.
# 
#  This software is provided "as-is" without any express or implied warranty. This includes, but is not limited to,
#  the WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, and NONINFRINGEMENT. In no event shall the 
#  author(s) and/or copyright holders be held liable for any claim, damages, or other liability, whether in an action 
#  of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other
#  dealings in the software. 
# 
#  Users are granted the rights to use, modify, and distribute this software.
#
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################

error_exit() {
    local message="$1"
    printf "Error: %s\n" "${message}" >&2
    printf "Error: %s\n" "${message}" 
    exit 1
} 

trap 'printf "\e[?25h\n"; exit 1' SIGINT SIGTERM

# Variables
DEFAULT_PROMPT="Press any key to continue..."
SCRIPT="${0##*/}"
RETURN_TEXT=""
TIMER=0
VERSION="5.0.2"
QUIET_MODE=0
ECHO_CHAR=0
COPYRIGHT="GPL3.0 only. Software is intended for free use and open source."
DESCRIPTION="A simple script that interrupts the current process until user presses key or optional timer reaches 00."

# Timer details

sanitize() {
    local input="$1"
    # This Bash parameter expansion removes control characters (ASCII 0-31 and 127)
    # as well as the ESC character itself (ASCII 27).
    local cleaned="${input//[$'\x00'-$'\x1f'$'\x7f']/}"
    printf "%s" "${cleaned}"
}

# Declare an associative array to store the mapping
declare -A OPT_MAP
OPT_MAP["--prompt"]="-p"
OPT_MAP["--timer"]="-t"
OPT_MAP["--response"]="-r"
OPT_MAP["--help"]="-h"
OPT_MAP["--quiet"]="-q"
OPT_MAP["--echo"]="-e"

ARGS=()

while [[ "$#" -gt 0 ]]; do
    CURRENT_ARG="$1"
    
    # Check if the current argument exists as a key in our map
    if [[ -n "${OPT_MAP[${CURRENT_ARG}]}" ]]; then
        # If yes, add the mapped short value to our argument list
        ARGS+=("${OPT_MAP[${CURRENT_ARG}]}")
    else
        # Otherwise, keep the original argument (e.g., a value or short flag)
        ARGS+=("${CURRENT_ARG}")
    fi
    
    shift
done

set -- "${ARGS[@]}"

HELP_TEXT="$(cat <<helpText 
${SCRIPT} ${VERSION}
${COPYRIGHT} ${DESCRIPTION}
Command: pause
Options: [-p|--prompt <TEXT>] [-r|--response <TEXT>] [-t|--timer <NUMBER>] 
         [-q|--quiet] [-e|--echo ] [-h|--help]

Usage: 
[--prompt, -p "<TEXT>"]   (Prompt text must be inside double quotes, example: pause -p "Hello World", 
                            or pause --prompt "Hello World". Output is to stderr)
[--response, -r "<TEXT>"] (Response text must be inside double quotes, example: pause -r "Thank you. Continuing...",
                            or pause --response "Thank you. Continuing..". Output is to stderr)
[--timer, -t <NUMBER> ]   (NUMBER is total seconds for delay.)
[--quiet, -q ]            (No prompt, just cursor blink. Timer must be set for use. Example: pause -q -t 10, 
                            or pause --quiet --timer 10, or pause -qt10 for simplicity.)
                          [You can combine the quiet mode options, such as: pause -qt10]
[--echo, -e ]             (Echoes the key pressed character to stdout for passing to a variable. )

Examples:
    Input: ${SCRIPT}
    Output: ${DEFAULT_PROMPT}
    Input: ${SCRIPT} -t 10 
    Output: $ [10] ${DEFAULT_PROMPT}
    Input: ${SCRIPT} -t 10 -p "Hello World" ${SCRIPT}
    Output: $ [10] Hello World
    Input: ${SCRIPT} -t 10 -p "Hello World" -r "And here we go."
    Output: $ [10] Hello World
            $ And here we go.
helpText
)"

# Parse command-line arguments
while getopts "eqt:p:r:h" OPTION; do
    case "${OPTION}" in
        t)  
            if [ -n "${OPTARG}" ]; then
                TIMER="${OPTARG}"
            elif [[ ! "${OPTARG}" =~ ^[0-9]+$ ]]; then
                error_exit "Timer must be a non-negative integer."
            else
                error_exit "Timer value must be provided."
            fi ;;

        p)  if [[ -n "${OPTARG}" ]] ; then DEFAULT_PROMPT=$(sanitize "${OPTARG}"); else error_exit "TEXT value must be provided." ; fi
            ;;

        r)  if [[ -n "${OPTARG}" ]] ; then RETURN_TEXT=$(sanitize "${OPTARG}"); else error_exit "TEXT value must be provided." ; fi 
        ;;

        h) 
            printf "%s\n" "${HELP_TEXT}"
            exit 0 ;;
        q) 
            QUIET_MODE=1 ;;
        e)  ECHO_CHAR=1 ;;
        ?) 
            error_exit "Invalid option. Use -h for help." ;;
    esac
done
shift "$((OPTIND - 1))"

# Function to display the remaining time in the desired format
display_time() {
    local total_seconds="$1"
    
    # Calculate time components
    local years=$(( total_seconds / 31536000 ))
    local months=$(( (total_seconds % 31536000) / 2592000 ))
    local days=$(( (total_seconds % 2592000) / 86400 ))
    local hours=$(( (total_seconds % 86400) / 3600 ))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local seconds=$(( total_seconds % 60 ))

    # Output format
    printf '['
    [[ ${years} -gt 0 || ${active} == "true" ]] && { _output+="$(printf '%02dyr:' "${years}")"; active="true"; }
    [[ ${months} -gt 0 || ${active} == "true" ]] && { _output+="$(printf '%02dmn:' "${months}")"; active="true"; }
    [[ ${days} -gt 0 || ${active} == "true" ]] && { _output+="$(printf '%02ddy:' "${days}")"; active="true"; }
    [[ ${hours} -gt 0 || ${active} == "true" ]] && { _output+="$(printf '%02d:' "${hours}")"; active="true"; }
    [[ ${minutes} -gt 0 || ${active} == "true" ]] && { _output+="$(printf '%02d:' "${minutes}")"; active="true"; }
    printf '%02d]' "${seconds}"
}

# Function for the quiet countdown
countdown() {
    local loop_count="$1"
    local text_prompt="$2"
    local return_prompt="$3"
    local quiet_mode=${QUIET_MODE}
    local start_time
    start_time=$(date "+%s") 
    
    if [ "${quiet_mode}" -eq 0 ]; then
        printf "\e[?25l" # hide cursor
        # Print initial line once
        printf '\r'  # Go to column 0
        display_time "${loop_count}"
        printf ' %s' "${text_prompt}"
    fi

    while (( loop_count > 0 )); do
        read -rsn1 -t 0.1 key_pressed ; status=$?
        case "${key_pressed}" in
                $'\e') read -rsn5 ;; # Ignore special keys
                [[:print:]])            
                    if [[ ${status} -eq 0 ]]; then 
                        loop_count=0; 
                        if [[ "${ECHO_CHAR}" -eq 1 ]]; then 
                            printf '%s' "${key_pressed}"; 
                        break; 
                        fi
                    fi
        esac

        if (( $(date "+%s") - start_time >= 1 )); then
            loop_count=$((loop_count - 1))
            start_time=$(date "+%s") 
            
            if [ "${quiet_mode}" -eq 0 ]; then 
                printf '\r'
                display_time "${loop_count}"
                printf ' %s' "${text_prompt}"
            fi
        fi
    done
    
    if [ "${quiet_mode}" -eq 0 ]; then
        printf "\e[?25h" # show cursor
    fi

        if [[ -n ${return_prompt} ]]; then 
            # Added >&2 to ensure this prints to the terminal, not the variable
            printf '\r\n%s\n' "${return_prompt}" >&2
        else
            printf '\n' >&2
        fi
}

# Main logic based on quiet and timer flags
if [[ ${QUIET_MODE} -eq 0 && ${TIMER} -eq 0 ]]; then
    if read -rsn1 -p "${DEFAULT_PROMPT}" key_pressed ; then 
        loop_count=0
        
        # 1. Echo the keystroke to STDOUT so the command substitution captures it
        if [[ "${ECHO_CHAR}" -eq 1 ]]; then 
            printf '%s' "${key_pressed}"
        fi

        # 2. Redirect UI feedback to STDERR so the user sees it immediately
        #printf '\n' >&2
        if [[ -n ${RETURN_TEXT} ]]; then 
            # Added >&2 to ensure this prints to the terminal, not the variable
            printf '\r\n%s\n' "${RETURN_TEXT}" >&2
        else
            printf '\n' >&2
        fi
        exit 0
    fi

elif [[ ${QUIET_MODE} -eq 0 && ${TIMER} -gt 0 ]]; then
    printf "\e[?25l" # hide cursor
    countdown "${TIMER}" "${DEFAULT_PROMPT}" "${RETURN_TEXT}"
    printf "\e[?25h" # return/show cursor
    printf "\n\r"
    exit 0

elif [[ ${QUIET_MODE} -eq 1 && ${TIMER} -gt 0 ]]; then
    printf "\e[?25h" # return/show cursor
    countdown "${TIMER}" "${RETURN_TEXT}"  # Call quiet countdown function
    exit 0

elif [[ ${QUIET_MODE} -eq 1 && ${TIMER} -eq 0 ]]; then
    printf "Timer must be set.\n\r" 
    exit 1
fi
