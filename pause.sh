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
#  Options: [-p|--prompt "<TEXT>"] [-r|--response "<TEXT>"] [-t|--timer <NUMBER>] 
#           [-q|--quiet] [-e|--echo ] [-h|--help]
#  pause ( without any options)
#  $ Press any key to continue...
#
#  Script closes with the press of any printable character, [Space], and [Enter]. Ignores special characters.
#
#  Options:
#  -p, --prompt 
#       Sent to STDERR. TEXT must be inside double quotes
#  [-r, --response
#       Sent to STDERR. TEXT must be inside double quotes
#  -t, --timer
#       NUMBER in total seconds
#  -q, --quiet
#       No prompt, just cursor blink. Timer required
#  -e, --echo
#       Echoes the pressed key character to STDOUT.
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
COPYRIGHT="Copyright (c) 2025 Grawmpy (CSPhelps) <grawmpy@gmail.com>

This software is licensed under the GNU General Public License (GPL) 
version 3.0 only.
"
DESCRIPTION="
A simple script that interrupts the current process until user presses 
any alphanumeric key, space, Enter, or when optional timer reaches [00].
"

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
OPT_MAP["--version"]="-v"

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

Command: ${SCRIPT}
Options: [-p|--prompt "<TEXT>"] [-r|--response "<TEXT>"] [-t|--timer <NUMBER>] 
         [-q|--quiet] [-e|--echo ] [-h|--help]

Usage: 
-p, --prompt   
    Outputs to stderr. TEXT must be inside double quotes
-r, --response 
    Outputs to stderr. TEXT must be inside double quotes, 
-t, --timer
    NUMBER is total seconds
-p, --quiet
    No text, just cursor blink. Timer required
-e, --echo
    Echoes the key pressed character to stdout
-v, --version 
    ${SCRIPT^}'s current version

By separating outputs directly to STDOUT and STDERR, ${SCRIPT} is able
to be used in variable using command substitution. Otherwise the keypress 
is echoed to terminal.

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
while getopts "t:p:r:hqev" OPTION; do
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
        v)  printf '%s\n' "${SCRIPT} v${VERSION}" ;;
        ?) 
            error_exit "Invalid option. Use -h for help." ;;
    esac
done
shift "$((OPTIND - 1))"

[[ "${ECHO_CHAR}" -eq 1 && "${DEFAULT_PROMPT}" == "Press key to continue..." ]] && DEFAULT_PROMPT=""

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
        printf '%s' "\040${text_prompt}"
    fi

    while (( loop_count > 0 )); do
        read -rsn1 -t 0.1 key_pressed ; status=$?
        case "${key_pressed}" in
                $'\e') read -rsn5 ;; # Ignore special keys
                [[:print:]]|""|" ")            
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
             fi
        fi
    done
    
    if [ "${quiet_mode}" -eq 0 ]; then
        printf "\e[?25h" # show cursor
    fi

        if [[ -n ${return_prompt} ]]; then 
            printf '%s' "\r\n${return_prompt}\n\r"
        fi
}

# Main logic based on quiet and timer flags
if [[ ${QUIET_MODE} -eq 0 && ${TIMER} -eq 0 ]]; then

    read -rsn1 -t p "${DEFAULT_PROMPT}" 0.1 key_pressed >&2 ; status=$?
        case "${key_pressed}" in
            $'\e') read -rsn5 ;; # Ignore special keys
            [[:print:]]|""|" ") 
                # checks for any printable keys, space and Enter      
                if [[ ${status} -eq 0 ]]; then 
                    loop_count=0; 
                    if [[ "${ECHO_CHAR}" -eq 1 ]]; then 
                        printf '%s' "${key_pressed}"; 
                    fi
                fi
        esac

    if (( $(date "+%s") - start_time >= 1 )); then
        loop_count=$((loop_count - 1))
        start_time=$(date "+%s") 
        
        if [ "${quiet_mode}" -eq 0 ]; then 
            printf '\r'
            display_time "${loop_count}"
            printf '^s' "${text_prompt}"
        fi
    fi
    if [[ -n ${return_prompt} ]]; then 
        printf '%s' "\r\n${return_prompt}"
    fi
    exit 0

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
