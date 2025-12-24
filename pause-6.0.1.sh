#!/usr/bin/env bash
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#  Script: pause.sh
#  Version: 6.0.1
#  Author: Grawmpy (CSPhelps) <grawmpy@gmail.com>
#
#  Description: This script allows for the interruption of the current process until either the
#  option timer is set and reaches [00], or the user presses any alphanumeric, [Enter], or [Space] 
#  keys. If no timer is used, the process will be stopped indefinitely until the user continues 
#  thr process with the press of the key listed. Using the timer (in total seconds only) continues 
#  the current process without user interaction. Other options are: 
#
#  Command: pause
#  Options: [-p|--prompt "<TEXT>"] [-r|--response "<TEXT>"] [-t|--timer <NUMBER>] 
#           [-q|--quiet] [-e|--echo ] [-v|--version] [-h|--help]
#
#  Options:
#  -p, --prompt        
#       Directed to STDERR (>&2). TEXT must be inside double quotes
#  -r, --response      
#       Directed to STDERR (>&2). TEXT must be inside double quotes
#  -t , --timer        
#       NUMBER must be in total seconds. Uses monotonic comparison [ ${SECONDS} ] 
#       giving zero software lag time over extended periods.
#  -q, --quiet                 
#       Quiets the prompt, sets to NULL. Overrides any -p, --prompt setting.
#  -e, --echo
#       Directed to STDOUT. Using simple command substitution the key pressed is echoed 
#  -v, --version
#       Version of this script
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


if [[ ! -t 0 ]]; then # Check if this script is started from terminal or tty
    printf '%s' "Piping through this script is not allowed."
    exit 1
fi

error_exit() { # Error handling to make sure to send failure code 1 as well as message
    local message="$1"
    printf "Error: %s\n" "${message}" 1>&2
    exit 1
} 

# trap the exit in case someone cancels without pressing key, returns prompt to default
trap 'printf "\e[?25h\n"; exit 1' SIGINT SIGTERM 

# set global variables
PROMPT_TEXT="Press [Enter] to continue..."
SCRIPT="${0##*/}" # script name
RETURN_TEXT=""
TIMER=0
QUIET_MODE=0
ECHO_CHAR=0

# help file information
VERSION="6.0.1"
COPYRIGHT="Copyright (c) 2025 Grawmpy (CSPhelps) <grawmpy@gmail.com>
This software is licensed under the GNU General Public License (GPL) 
version 3.0 only."
DESCRIPTION="A simple script that interrupts the current process until user presses \
any alphanumeric key, [Space], [Enter], or optional timer reaches [00]."

# This Bash parameter expansion removes control characters (ASCII 0-31 and 127)
# as well as the ESC character itself (ASCII 27).
sanitize() {
    local input="$1"
    local cleaned="${input//[$'\x00'-$'\x1f'$'\x7f']/}"
    printf "%s" "${cleaned}"
}

# Declare an associative array to store the mapping
declare -A OPT_MAP
OPT_MAP["--echo"]="-e"
OPT_MAP["--help"]="-h"
OPT_MAP["--prompt"]="-p"
OPT_MAP["--quiet"]="-q"
OPT_MAP["--response"]="-r"
OPT_MAP["--timer"]="-t"
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

cr=$(printf '\n')

HELP_TEXT="$(cat <<helpText 
${SCRIPT} v.${VERSION}

${COPYRIGHT} 
${DESCRIPTION}

Command: ${SCRIPT}
Options: [-e|--echo ] [-h|--help] [-p|--prompt "<TEXT>"] [-q|--quiet] 
         [-r|--response "<TEXT>"] [-t|--timer <NUMBER>] [-v, --version]

Usage: 
-e, --echo
    Outputs to STDOUT. Without prompt option this will assume a null -p, --prompt value
-h, --help
    This text
-p, --prompt  
    Outputs to STDERR. Prompt text must be inside quotes. 
-q, --quiet
    Quiets the prompt, sets to [Space]. Overrides -p, --prompt setting.
-r, --response
    Outputs to STDERR. Response text must be inside quotes, 
-t, --timer    
    SECONDS is total seconds for delay. Uses monotonic comparison for zero lag time
    over extended periods.
-v, --version
    Current version
${cr}
helpText
)"

# Parse command-line arguments
while getopts ":ehp:qr:t:v" OPTION; do
    case "${OPTION}" in
        e)  ECHO_CHAR=1 # Set echo on
            ;;

        h)  printf "%s\n" "${HELP_TEXT}"
            exit 0 
            ;;

        p)  if [[ -n "${OPTARG}" ]] ; then 
                PROMPT_TEXT=$(sanitize "${OPTARG}"); # Remove escape characters
            else 
                error_exit "TEXT value must be provided." ; 
            fi
            ;;

        q)  QUIET_MODE=1 # Set quiet on
            PROMPT_TEXT=" " # Set prompt to space
            ;;

        r)  if [[ -n "${OPTARG}" ]] ; then 
                RETURN_TEXT=$(sanitize "${OPTARG}"); # Remove escape characters
            else 
                error_exit "TEXT value must be provided." ; 
            fi 
            ;;

        t)  if [[ -n "${OPTARG}" ]] ; then
                if [[ "${OPTARG}" =~ ^[0-9]+$ ]]; then
                    TIMER="${OPTARG}"
                else
                    error_exit "Timer value [${OPTARG}] must be a non-negative integer."
                fi 
            fi
            ;;

        v)  printf '%s v.%s\n' "${SCRIPT}" "${VERSION}" ; exit 0 # Script and version number
            ;;

        ?) 
            error_exit "Invalid option. Use -h, --help for more information on usage." ;;
    esac
done

shift $((OPTIND - 1))
if [[ $# -gt 0 ]]; then
    error_exit "Unexpected positional parameters detected. Use ${SCRIPT} -h or --help for help for parameters."
fi

# Function to display the remaining time in the desired format
display_time() {
    local total_seconds="$1"
    
    # Calculate time components
    local years=$(( total_seconds / 31536000 ))
    local months=$(( (total_seconds / 2592000) % 12 ))
    local days=$(( (total_seconds / 86400) % 30 ))
    local hours=$(( (total_seconds / 3600) % 24 ))
    local minutes=$(( (total_seconds / 60) % 60 ))
    local seconds=$(( total_seconds % 60 ))

    # Output format
    # Output format
    printf '['
    # Use a local string to build the output to avoid printf glitches
    [[ ${years} -gt 0 ]] && { printf '%02dyr:' "${years}"; active="true"; }
    [[ ${months} -gt 0 || ${active} == "true" ]] && { printf '%02dmn:' "${months}"; active="true"; }
    [[ ${days} -gt 0 || ${active} == "true" ]] && { printf '%02ddy:' "${days}"; active="true"; }
    [[ ${hours} -gt 0 || ${active} == "true" ]] && { printf '%02d:' "${hours}"; active="true"; }
    [[ ${minutes} -gt 0 || ${active} == "true" ]] && { printf '%02d:' "${minutes}"; active="true"; }
    printf '%02d]' "${seconds}"
}

# Countdown timer function
countdown() {
    SECONDS=0
    local loop_count="$1"
    local text_prompt="$2"
    local return_prompt="$3"
    local start_time
    start_time=${SECONDS} 
    
    # Hide cursor only if NOT in quiet mode (per your preference)
    [[ ${QUIET_MODE} -eq 0 ]] && printf "\e[?25l"

    if [[ ${QUIET_MODE} -eq 0 ]]; then
        printf '\r'
        display_time "${loop_count}"
        printf ' %s' "${text_prompt}"
    fi
    
    while (( loop_count > 0 )); do
        read -rsn1 -t 0.1 key_pressed
        status=$?
        
        # Handle keypress
        if [[ ${status} -eq 0 ]]; then
            [[ "${ECHO_CHAR}" -eq 1 ]] && printf '%s' "${key_pressed}"
            loop_count=0
            break
        fi

        # Update display every 1 second
        if (( SECONDS - start_time >= 1 )); then
            loop_count=$((loop_count - 1))
            start_time=${SECONDS} 
            
            if [[ ${QUIET_MODE} -eq 0 ]]; then 
                printf '\r'
                display_time "${loop_count}"
                printf ' %s' "${text_prompt}"
            fi
        fi
    done
    
    # Restore cursor
    [[ ${QUIET_MODE} -eq 0 ]] && printf "\e[?25h"
    
    # Print out the response text
    if [[ ${QUIET_MODE} -eq 0 ]]; then
        if [[ -n ${return_prompt} ]]; then 
            printf '\r\n%s\n' "${return_prompt}" >&2
        else
            printf '\n' >&2
        fi
    fi
}

# Main logic for running 
if [[ ${TIMER} -gt 0 ]]; then
    # handles all timer function calls 
    countdown "${TIMER}" "${PROMPT_TEXT}" "${RETURN_TEXT}"
    exit 0
else
    # Determine the prompt to show
    ACTIVE_PROMPT=""
    [[ ${QUIET_MODE} -eq 0 ]] && ACTIVE_PROMPT="${PROMPT_TEXT}" # Check if QUIET_MODE is not set and sets prompt to 

    # Execution
    if read -rsn1 -p "${ACTIVE_PROMPT}" key_pressed; then
        # Handle echo if enabled
        [[ "${ECHO_CHAR}" -eq 1 ]] && printf '%s' "${key_pressed}"

        # Show return text if provided
            if [[ -n ${RETURN_TEXT} ]]; then
                printf '\r\n%s\n' "${RETURN_TEXT}" >&2
            else
                printf '\n' >&2
            fi
        exit 0
    fi
fi
# --- END OF NEW MAIN LOGIC ---
