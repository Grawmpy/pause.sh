#!/usr/bin/env bash
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#  pause.sh
VERSION='5.0.1'
#  Author: Grawmpy (CSPhelps) <grawmpy@gmail.com>

#  Description: This script allows for the interruption of the current process until either the
#  timer reaches 00 or the user presses any key. If no timer is used, the process
#  will be stopped indefinitely until the user manually continues the process with
#  the press of any key except shift. Using the timer (in seconds only) continues 
#  the current process without user interaction. The order of the variables can be passed 
#  to the script in any order, doesn't matter, they are processed as they are read and 
#  the result is stored until applied to the final output.
#
#  I am an old school DOS user starting in college in 1983 as a Computer Science major. 
#  From the very early days, "pause" has been a simple function that has always been a
#  part of the windows commands that is a minute feature, but can be very useful at times. The options
#  I have added as options are ones I would have liked to have seen included and easily accessible
#  from a simple option passed to the command. This is my best attempt to add those same features
#  I felt were major deficiencies and should have been added to the pause program. I know some would 
#  argue that this script is a bit superfluous and not really needed. In a way you're right, you can
#  add a few lines to do what all I do here but why do all that when you can simple use the command "pause" and 
#  and have built-in options to customize it without having to the coding yourself.

#  Command: pause
#  Options: [-p|--prompt] [-r|--response] [-t|--timer] [-q|--quiet] [-h|--help]
#  pause ( without any options)
#  $ Press any key to continue...
#
#  Options include:
#  [--prompt, -p] (prompt text must be inside double quotes, example: pause -p "Hello World", or pause --prompt "Hello World")
#  [--response, -r ] (response text must be inside double quotes)
#  [--timer, -t ] (Must be in total seconds. Example: pause -t 30, or pause --timer 30
#  [--quiet, -q ] (No prompt, just cursor blink. Timer must be set for use. Example: pause -q -t 10, or pause --quiet --timer 10)
#  You can combine the quiet mode options, such as: pause -qt10
#  Order of options does not matter as they are processed when they are encountered by getopts and used later in the main logic.

#  1. I wanted the script to have a way to change the default prompt to a custom text to accommodate for the needs of the user. 
#  2. I wanted a way to use a custom response, if needed, echoed after the process continued. 
#  3. I wanted a quiet countdown that could pause a process for a set time to wait for whatever reason with no prompt.
#  4. I wanted an easy way to use a countdown timer. This is not meant to be super accurate but I tried to keep the
#     lag time to a minimum. It does have a little lag time so over time it will lose accuracy. The extended time
#     separation was simply for fun. I added the countdown in years, months, days, and the hours and minute displayed as [00:00].
#     Each section disappears as the countdown reaches zero. Format: [00yr:00mn:00dy:00:00]. Final will be [00].
#  5. I wanted to make sure that only an alphanumeric key the user pressed closed the pause script and continued the process.
#     I tried to eliminate the function, arrow, shift, ctrl or alt keys being recognized to continue the process. 
#     I wanted it to be functional for use in passing on the character pressed to be used anywhere the capture of 
#     a single alphanumeric key press is needed.
#  6. I wanted to use as pure bash as possible to allow for maximum usage and broad compatibility .
#  

#  Copyright: GPL 3.0, THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
#  SOFTWARE. 
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################

# Variables
DEFAULT_PROMPT="Press any key to continue..."
SCRIPT="${0##*/}"
RETURN_TEXT=""
KEY_PRESS=""
ECHO_CHAR=0
TIMER=0
QUIET_MODE=0
COPYRIGHT="GPL3.0 License. Software is intended for free use only."
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

# Parse command-line arguments
while getopts "eqt:p:r:h" OPTION; do
    case "${OPTION}" in
        t)  
            if [ -z "${OPTARG}" ]; then
                error_exit "Timer value must be provided."
            elif [[ ! "${OPTARG}" =~ ^[0-9]+$ ]]; then
                error_exit "Timer must be a non-negative integer."
            else
                TIMER="${OPTARG}"
            fi ;;
        p) 
            DEFAULT_PROMPT=$(sanitize "${OPTARG}") ;;
        r) 
            RETURN_TEXT=$(sanitize "${OPTARG}") ;;
        h) 
            printf "%s\n" "${SCRIPT}" "${VERSION}" "${COPYRIGHT}" "${DESCRIPTION}"
            printf "Usage:\n"
            printf "[-p|--prompt] [-t|--timer] [-r|--response] [-h|--help] [-q|--quiet]\n\n"
            printf "    -p, --prompt    [ input required (string must be in quotes) ]\n"
            printf "    -t, --timer     [ number of seconds ]\n"
            printf "    -r, --response  [ requires text (string must be in quotes) ]\n"
            printf "    -h, --help      [ this information ]\n"
            printf "    -q, --quiet     [ quiet text, requires timer to be set. ]\n\n"
            printf ''
            printf "Examples:\n"
            printf "    Input: %s\n" "${SCRIPT}"
            printf "    Output: %s\n" "${DEFAULT_PROMPT}"
            printf "    Input: %s -t 10\n" "${SCRIPT}"
            printf "    Output: $ [10] %s\n" "${DEFAULT_PROMPT}"
            printf "    Input: %s -t 10 -p \"Hello World\"\n" "${SCRIPT}"
            printf "    Output: $ [10] Hello World\n"
            printf "    Input: %s -t 10 -p \"Hello World\" -r \"And here we go.\"\n" "${SCRIPT}"
            printf "    Output: $ [10] Hello World\n"
            printf "            $ And here we go.\n"
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
    [[ ${years} -gt 0 ]] && printf '%02dyr:' "${years}"
    [[ ${months} -gt 0 ]] && printf '%02dmn:' "${months}"
    [[ ${days} -gt 0 ]] && printf '%02ddy:' "${days}"
    [[ ${hours} -gt 0 ]] && printf '%02d:' "${hours}"
    [[ ${minutes} -gt 0 ]] && printf '%02d:' "${minutes}"
    printf '%02d]' "${seconds}"
}

# Function for the quiet countdown
quiet_countdown() {
    local loop_count="$1"
    local return_prompt="$2"
    local status
    local start_time
    start_time=$(date +%s)  # Get the starting time
    local elapsed_time=0

    # Loop for countdown
    while (( loop_count > 0 )); do
        # Update elapsed time
        elapsed_time=$(( $(date +%s) - start_time ))

        # Check if a second has passed
        if (( elapsed_time >= 1 )); then
            loop_count=$((loop_count - 1))  # Decrement if a second has elapsed
            start_time=$(date +%s)  # Reset the start time
        fi

        # Check for key press without displaying anything
        read -r -t 0.1 KEY_PRESS
        status=$?
        if [[ ${status} -eq 0 ]]; then loop_count=0;
            [[ ${ECHO_CHAR} -eq 1 ]] && printf '%s' "${KEY_PRESS}"
            printf "\n" >&2
            break; 
        fi
        
        [[ ${ECHO_CHAR} -eq 1 ]] && printf '%s' "${KEY_PRESS}"

    done

    # After countdown is finished
    printf '\n'   # Move to a new line
    if [[ -n ${return_prompt} ]]; then 
        printf '%s\n' "${return_prompt}"  # Print the return prompt if provided
    fi
}

interrupt() {
    local loop_count="$1"
    local text_prompt="$2"
    local return_prompt="$3"
    local QUIET_MODE=${QUIET_MODE}
    local start_time
    start_time=$(date +%s)
    
    if [ "${QUIET_MODE}" -eq 0 ]; then
        printf "\e[?25l" # hide cursor
        # Print initial line once
        printf '\r'  # Go to column 0
        display_time "${loop_count}"
        printf ' %s' "${text_prompt}"
    fi

    while (( loop_count > 0 )); do
        read -r -t 0.1 KEY_PRESS; status=$?
        if [[ ${status} -eq 0 ]]; then loop_count=0;
            [[ ${ECHO_CHAR} -eq 1 ]] && printf '%s' "${KEY_PRESS}"
            printf "\n" >&2
            break; 
        fi
        
        if (( $(date +%s) - start_time >= 1 )); then
            loop_count=$((loop_count - 1))
            start_time=$(date +%s)
            
            if [ "${QUIET_MODE}" -eq 0 ]; then 
                # --- The Non-Blinking Update Idea ---
                # 1. Move cursor back to column 0
                # 2. Re-display the entire line (overwriting the old one)
                # This is the smoothest way without tracking previous string length.
                printf '\r'
                display_time "${loop_count}"
                printf ' %s' "${text_prompt}"
            fi
        fi
    done
    
    if [ "${QUIET_MODE}" -eq 0 ]; then
        printf "\e[?25h" # show cursor
    fi
    printf '\n'
    [[ -n ${return_prompt} ]] && printf '%s\n' "${return_prompt}"
}


# Main logic based on quiet and timer flags
if [[ ${QUIET_MODE} -eq 0 && ${TIMER} -eq 0 ]]; then
    # Capture the key here
    read -rsn1 -p "${DEFAULT_PROMPT}" KEY_PRESS ; status=$?
        if [[ ${status} -eq 0 ]]; then loop_count=0;
            [[ ${ECHO_CHAR} -eq 1 ]] && printf '%s' "${KEY_PRESS}"
            printf "\n" >&2 
        fi
    exit 0

elif [[ ${QUIET_MODE} -eq 0 && ${TIMER} -gt 0 ]]; then
    interrupt "${TIMER}" "${DEFAULT_PROMPT}" "${RETURN_TEXT}"
    # KEY_PRESS was set inside interrupt()
    printf "\n\r"
    exit 0

elif [[ ${QUIET_MODE} -eq 1 && ${TIMER} -gt 0 ]]; then
    quiet_countdown "${TIMER}" "${RETURN_TEXT}"
    # KEY_PRESS was set inside quiet_countdown()
    printf "\n\r"
    exit 0

elif [[ ${QUIET_MODE} -eq 1 && ${TIMER} -eq 0 ]]; then
    printf "Timer must be set.\n\r" 
    exit 1
fi
