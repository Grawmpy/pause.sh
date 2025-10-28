#!/usr/bin/bash
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#  pause.sh
VERSION='5.0'
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

# Variables
DEFAULT_PROMPT="Press any key to continue..."
RETURN_TEXT=""
SCRIPT="${0##*/}"
COPYRIGHT="MIT License. Software is intended for free use."
DESCRIPTION="A simple script that interrupts the current process."

# Timer details
declare -i TIMER=0
declare -i QUIET_MODE=0

error_exit() { # Error for any wrong input to the switches
    echo "$1"
    exit 1
}

# Parse command-line arguments
while getopts "qt:p:r:h" OPTION; do
    case "$OPTION" in
        t)  if [[ -z $OPTARG ]]; then
            error_exit "Timer value must be provided."
        elif [[ ! $OPTARG =~ ^[0-9]+$ ]]; then
            error_exit "Timer must be a non-negative integer."
        else
            TIMER="$OPTARG"
        fi ;;
        p) DEFAULT_PROMPT="${OPTARG}" ;;
        r) RETURN_TEXT="${OPTARG}" ;;
        h)
            printf "%s v.%s\n%s\n%s\n\n" "$SCRIPT" "$VERSION" "$COPYRIGHT" "$DESCRIPTION"
            printf "Usage:\n"
            printf "%s [-p|--prompt] [-t|--timer] [-r|--response] [-h|--help] [-q|--quiet]\n\n" "$SCRIPT"
            printf "    -p, --prompt    [ input required (string must be in quotes) ]\n"
            printf "    -t, --timer     [ number of seconds ]\n"
            printf "    -r, --response  [ requires text (string must be in quotes) ]\n"
            printf "    -h, --help      [ this information ]\n"
            printf "    -q, --quiet     [ quiet text, requires timer to be set. ]\n\n"
            printf "Examples:\n"
            printf "Input:  $ %s\nOutput: $ %s\n" "$SCRIPT" "$DEFAULT_PROMPT"
            printf "Input:  $ %s -t <seconds>\nOutput: $ [timer] %s\n" "$SCRIPT" "$DEFAULT_PROMPT"
            exit 0 ;;
        q) QUIET_MODE=1 ;;
        ?) error_exit "Invalid option. Use -h for help." ;;
    esac
done

shift "$((OPTIND - 1))"

# Function to display the remaining time in the desired format
display_time() {
    local total_seconds="$1"
    
    # Calculate time components
    local years=$(( total_seconds / 31536000 ))
    local months=$(( (total_seconds % 31536000) / 2592000 ))  # Roughly 30 days per month
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

# Timer countdown function
interrupt() {
    local LOOP_COUNT="$1"
    local text_prompt="$2"
    local return_prompt="$3"
    local start_time=$(date +%s)  # Get the starting time

    # Loop for countdown
    while (( LOOP_COUNT > 0 )); do
        local elapsed_time=$(( $(date +%s) - start_time ))  # Calculate elapsed time

        # Update display if one second has passed
        if (( elapsed_time >= 1 )); then
            LOOP_COUNT=$((LOOP_COUNT - 1))  # Decrement if a second has elapsed
            start_time=$(date +%s)  # Reset the start time
        fi

        printf '\r\033[K'  # Clear the line 
        display_time "$LOOP_COUNT"  # Display formatted time
        printf ' %s' "$text_prompt"  # Display the prompt

        # Check for key press
        read -r -t 0.1 -s key  # Wait for key press for a short interval
        if [[ $? -eq 0 ]]; then
            LOOP_COUNT=0
        fi
    done
    printf '\n'  # Move to a new line

    if [[ -n $return_prompt ]]; then 
        printf '%s\n' "$return_prompt"
    fi
}

# Main logic based on quiet and timer flags
if [[ $QUIET_MODE -eq 0 && $TIMER -eq 0 ]]; then
    read -rsn1 -p "$DEFAULT_PROMPT" 
    echo
    exit 0
elif [[ $QUIET_MODE -eq 0 && $TIMER -gt 0 ]]; then
    interrupt "$TIMER" "$DEFAULT_PROMPT" "$RETURN_TEXT"
    exit 0
elif [[ $QUIET_MODE -eq 1 && $TIMER -eq 0 ]]; then
    echo "Timer must be set." 
    exit 1
fi
