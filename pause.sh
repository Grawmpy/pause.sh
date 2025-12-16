#!/usr/bin/env bash
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#  pause.sh
VERSION='5.0.1'
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

# Variables
DEFAULT_PROMPT="Press any key to continue..."
SCRIPT="${0##*/}"
RETURN_TEXT=""
TIMER=0
QUIET_MODE=0
COPYRIGHT="MIT License. Software is intended for free use only."
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

ARGS=()

while [[ "$#" -gt 0 ]]; do
    CURRENT_ARG="$1"
    
    # Check if the current argument exists as a key in our map
    if [[ -n "${OPT_MAP[$CURRENT_ARG]}" ]]; then
        # If yes, add the mapped short value to our argument list
        ARGS+=("${OPT_MAP[$CURRENT_ARG]}")
    else
        # Otherwise, keep the original argument (e.g., a value or short flag)
        ARGS+=("$CURRENT_ARG")
    fi
    
    shift
done

set -- "${ARGS[@]}"

# Parse command-line arguments
while getopts "qt:p:r:h" OPTION; do
    case "$OPTION" in
        t)  
            if [ -z "$OPTARG" ]; then
                error_exit "Timer value must be provided."
            elif [[ ! "$OPTARG" =~ ^[0-9]+$ ]]; then
                error_exit "Timer must be a non-negative integer."
            else
                TIMER="$OPTARG"
            fi ;;
        p) 
            DEFAULT_PROMPT=$(sanitize "$OPTARG") ;;
        r) 
            RETURN_TEXT=$(sanitize "$OPTARG") ;;
        h) 
            printf "%s\n" "$SCRIPT" "$VERSION" "$COPYRIGHT" "$DESCRIPTION"
            printf "Usage:\n"
            printf "[-p|--prompt] [-t|--timer] [-r|--response] [-h|--help] [-q|--quiet]\n\n"
            printf "    -p, --prompt    [ input required (string must be in quotes) ]\n"
            printf "    -t, --timer     [ number of seconds ]\n"
            printf "    -r, --response  [ requires text (string must be in quotes) ]\n"
            printf "    -h, --help      [ this information ]\n"
            printf "    -q, --quiet     [ quiet text, requires timer to be set. ]\n\n"
            printf ''
            printf "Examples:\n"
            printf "    Input: %s\n" "$SCRIPT"
            printf "    Output: %s\n" "$DEFAULT_PROMPT"
            printf "    Input: %s -t 10\n" "$SCRIPT"
            printf "    Output: $ [10] %s\n" "$DEFAULT_PROMPT"
            printf "    Input: %s -t 10 -p \"Hello World\"\n" "$SCRIPT"
            printf "    Output: $ [10] Hello World\n"
            printf "    Input: %s -t 10 -p \"Hello World\" -r \"And here we go.\"\n" "$SCRIPT"
            printf "    Output: $ [10] Hello World\n"
            printf "            $ And here we go.\n"
            exit 0 ;;
        q) 
            QUIET_MODE=1 ;;
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
    [[ $years -gt 0 ]] && printf '%02dyr:' "$years"
    [[ $months -gt 0 ]] && printf '%02dmn:' "$months"
    [[ $days -gt 0 ]] && printf '%02ddy:' "$days"
    [[ $hours -gt 0 ]] && printf '%02d:' "$hours"
    [[ $minutes -gt 0 ]] && printf '%02d:' "$minutes"
    printf '%02d]' "$seconds"
}

# Function for the quiet countdown
quiet_countdown() {
    local LOOP_COUNT="$1"
    local return_prompt="$2"
    local status
    local start_time
    start_time=$(date +%s)  # Get the starting time
    local elapsed_time=0

    # Loop for countdown
    while (( LOOP_COUNT > 0 )); do
        # Update elapsed time
        elapsed_time=$(( $(date +%s) - start_time ))

        # Check if a second has passed
        if (( elapsed_time >= 1 )); then
            LOOP_COUNT=$((LOOP_COUNT - 1))  # Decrement if a second has elapsed
            start_time=$(date +%s)  # Reset the start time
        fi

        # Check for key press without displaying anything
        read -r -t 0.1
        status=$?
        if [[ ${status} -eq 0 ]]; then
            LOOP_COUNT=0  # Exit countdown if a key is pressed
        fi
    done

    # After countdown is finished
    printf '\n'   # Move to a new line
    if [[ -n $return_prompt ]]; then 
        printf '%s\n' "$return_prompt"  # Print the return prompt if provided
    fi
}

interrupt() {
    local LOOP_COUNT="$1"
    local text_prompt="$2"
    local return_prompt="$3"
    local quiet_mode=$QUIET_MODE
    local start_time
    start_time=$(date +%s)
    
    if [ "$quiet_mode" -eq 0 ]; then
        printf "\e[?25l" # hide cursor
        # Print initial line once
        printf '\r'  # Go to column 0
        display_time "$LOOP_COUNT"
        printf ' %s' "$text_prompt"
    fi

    while (( LOOP_COUNT > 0 )); do
        read -r -t 0.1; status=$?
        if [[ ${status} -eq 0 ]]; then LOOP_COUNT=0; break; fi
        
        if (( $(date +%s) - start_time >= 1 )); then
            LOOP_COUNT=$((LOOP_COUNT - 1))
            start_time=$(date +%s)
            
            if [ "$quiet_mode" -eq 0 ]; then 
                # --- The Non-Blinking Update Idea ---
                # 1. Move cursor back to column 0
                # 2. Re-display the entire line (overwriting the old one)
                # This is the smoothest way without tracking previous string length.
                printf '\r'
                display_time "$LOOP_COUNT"
                printf ' %s' "$text_prompt"
            fi
        fi
    done
    
    if [ "$quiet_mode" -eq 0 ]; then
        printf "\e[?25h" # show cursor
    fi
    printf '\n'
    [[ -n $return_prompt ]] && printf '%s\n' "$return_prompt"
}


# Main logic based on quiet and timer flags
if [[ $QUIET_MODE -eq 0 && $TIMER -eq 0 ]]; then
    read -rsn1 -p "$DEFAULT_PROMPT" 
    printf "\n\r"
    exit 0
elif [[ $QUIET_MODE -eq 0 && $TIMER -gt 0 ]]; then
    printf "\e[?25l" # hide cursor
    interrupt "$TIMER" "$DEFAULT_PROMPT"
    printf "\e[?25h" # return/show cursor
    [[ -n $RETURN_TEXT ]] && printf '%s\n' "$RETURN_TEXT"  # Print the return text if it exists
    printf "\n\r"
    exit 0
elif [[ $QUIET_MODE -eq 1 && $TIMER -gt 0 ]]; then
    printf "\e[?25h" # return/show cursor
    quiet_countdown "$TIMER" "$RETURN_TEXT"  # Call quiet countdown function
    exit 0
elif [[ $QUIET_MODE -eq 1 && $TIMER -eq 0 ]]; then
    printf "Timer must be set.\n\r" 
    exit 1
fi
