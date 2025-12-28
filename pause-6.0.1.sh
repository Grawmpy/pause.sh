#!/usr/bin/env bash
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#  Script: pause.sh
#  Version: 6.0.1
#  Author: Grawmpy (CSPhelps) <grawmpy@gmail.com>
#
# Created: 2025-12-27 23:28:02Z
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
#       NUMBER must be in total seconds.
#  -q, --quiet                 
#       Quiets the prompt, sets to NULL. Overrides any -p, --prompt setting.
#  -e, --echo
#       Directed to STDOUT. Using simple command substitution the key pressed is echoed 
#  -v, --version
#       Version of this script
#
#  How it works
#  ------------
#  * The script reads the kernel’s monotonic clock (CLOCK_MONOTONIC) via
#    system boot and never goes backwards.
#  * Each loop iteration records the current monotonic value, subtracts the
#    value taken at the start of the previous second, and checks whether
#    at least 1 000 ms have elapsed.
#  * Because the comparison uses only monotonic values, the timer cannot
#    lose or gain time due to wall‑clock adjustments.
#
#  Result
#  -------
#  The countdown finishes after exactly the number of seconds you asked
#  for, with sub‑millisecond precision, regardless of system‑time changes.
#
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
DESCRIPTION=$(printf '%s\n%s' "A simple script that interrupts the current process until user presses" "any alphanumeric key, [Space], [Enter], or optional timer reaches [00].")

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
${cr}
Copyright: ${COPYRIGHT} 
Description: ${DESCRIPTION}
${cr}
Command: ${SCRIPT}
Options: [-e|--echo ] [-h|--help] [-p|--prompt "<TEXT>"] [-q|--quiet] 
         [-r|--response "<TEXT>"] [-t|--timer <NUMBER>] [-v, --version]
${cr}
Usage: 
-e, --echo
    Outputs to STDOUT. Will assume default prompt: Press [Enter] to continue...
-h, --help
    This text
-p, --prompt  
    Outputs to STDERR. Changes the default prompt TEXT must be inside quotes. 
-q, --quiet
    Quiets the prompt, sets to [Space]. Overrides -p, --prompt setting.
-r, --response
    Outputs to STDERR. Adds response text after continueing process. TEXT must be inside quotes, 
-t, --timer    
    SECONDS is total seconds for delay. Uses monotonic clock for zero lag time
    eveen over extended periods. 
-v, --version
    Current version
${cr}
    Note: A monotonic clock is a timer that always moves forward at a constant rate 
        and never jumps backward. When you read the system clock you get the number 
        of seconds that have elapsed since the system boot, independent of any changes 
        to the wall-clock [like the calendar time you get from \$(date) can vary and
        lose or gain time].
        * The script reads the kernel's monotonic clock (CLOCK_MONOTONIC) via
          a tiny Perl/Python helper.  This clock counts nanoseconds since the
          system boot and never goes backwards.
        * Each loop iteration records the current monotonic value, subtracts the
          value taken at the start of the previous second, and checks whether
          at least 1000ms have elapsed.
        * Because the comparison uses only monotonic values, the timer cannot
          lose or gain time due to wall-clock adjustments.

        Result:
        The countdown finishes after exactly the number of seconds you asked
        for, with sub-millisecond precision, regardless of system-time changes.
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

# ------------------------------------------------------------
# monotonic_epoch_ms
#   Returns the current time as **milliseconds since the Unix epoch**
#   but the value is derived from the kernel’s monotonic clock,
#   so it never jumps backwards when the system clock is changed.
# ------------------------------------------------------------
monotonic_epoch_ms() {
    # ---------- Wall‑clock (seconds → nanoseconds) ----------
    local secs=$(date +%s)  # e.g. 1703821234
    local wall_ns=$(( secs * 1000000000 )) # nanoseconds since 1970‑01‑01

    # ---------- Monotonic clock (nanoseconds since boot) ----------
    # Use Perl (available on virtually every Unix).  If you prefer Python,
    # replace the line with the commented Python alternative.
    local mono_ns
    mono_ns=$(perl -MTime::HiRes -e 'printf "%d", Time::HiRes::clock_gettime(1)*1000000000')
    # Python alternative (uncomment if you have python3 but not perl):
    # mono_ns=$(python3 -c 'import time,sys; sys.stdout.write(str(int(time.monotonic()*1e9)))')

    # ---------- Constant offset: wall – monotonic ----------
    local offset_ns=$(( wall_ns - mono_ns ))

    # ---------- Current monotonic time again ----------
    local now_mono_ns
    now_mono_ns=$(perl -MTime::HiRes -e 'printf "%d", Time::HiRes::clock_gettime(1)*1000000000')
    # Python alternative:
    # now_mono_ns=$(python3 -c 'import time,sys; sys.stdout.write(str(int(time.monotonic()*1e9)))')

    # ---------- Convert nanoseconds → milliseconds ----------
    printf '%d' $(( (now_mono_ns + offset_ns) / 1000000 ))
}

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
    [[ ${years} -gt 0 ]] && { printf '%02dyr:' "${years}"; }
    [[ ${years} -gt 0 || ${months} -gt 0 ]] && { printf '%02dmn:' "${months}"; }
    [[ ${years} -gt 0 || ${months} -gt 0 || ${days} -gt 0 ]] && { printf '%02ddy:' "${days}"; }
    [[ ${years} -gt 0 || ${months} -gt 0 || ${days} -gt 0 || ${hours} -gt 0 ]] && { printf '%02d:' "${hours}"; }
    [[ ${years} -gt 0 || ${months} -gt 0 || ${days} -gt 0 || ${hours} -gt 0 || "${minutes}" -gt 0 ]] && { printf '%02d:' "${minutes}" ; }
    printf '%02d]' "${seconds}"
}

# Countdown timer function
countdown() {
    SECONDS=0
    local loop_count="$1"
    local text_prompt="$2"
    local return_prompt="$3"
    local starting_milsecs now_milsecs
    # Compatible with Bash 3.x and up
    # Using 10# forces decimal to prevent "octal" errors with leading zeros
    starting_milsecs=$(monotonic_epoch_ms)

    # Hide cursor only if NOT in quiet mode (per your preference)
    [[ ${QUIET_MODE} -eq 0 ]] && printf "\e[?25l"

    if [[ ${QUIET_MODE} -eq 0 ]]; then
        printf '\r'
        display_time "${loop_count}"
        printf ' %s' "${text_prompt}"
    fi
    
    while (( loop_count > 0 )); do
    
        read -rsn1 -t 0.001 key_pressed
        status=$?
        
        case $key_pressed in
            $'\e'*)
            # Capture up to 4 remaining bytes of the sequence immediately 
            # so they don't leak into the next loop iteration or command.
            read -rsn4 -t 0.001
            
            # Nullify the original key variable
            key_pressed="" 
            ;;
            [[:alnum:]]|""|" ") 
                    # Handle keypress
                if [[ ${status} -eq 0 ]]; then
                    [[ "${ECHO_CHAR}" -eq 1 ]] && printf '%s' "${key_pressed}"
                    loop_count=0
                    break
                fi

                now_milsecs=$(monotonic_epoch_ms)
                # Update display every 1 second
                    if [ $(( now_milsecs - starting_milsecs )) -ge 1000 ]; then
                    loop_count=$((loop_count - 1))
                    starting_milsecs=${now_milsecs}
                        if [[ ${QUIET_MODE} -eq 0 ]]; then 
                            printf '\r'
                            display_time "${loop_count}"
                            printf ' %s' "${text_prompt}"
                        fi
                    fi
                ;;
            esac
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
