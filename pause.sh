#!/bin/bash
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


error_exit() { 
    # Error for any wrong input to the switches
    printf "%s\n" "$1"
    exit 1
}

sanitize_input() {
    local input="$1"
    # Remove any characters that are not alphanumeric, space, or valid punctuation.
    # Ensure ranges and characters are in proper order.
    echo "$input" | tr -cd '[:alnum:][:blank:]_,.;:!' 
}
remove_escape_codes() {
    local input="$1"
    # Remove escape codes (like color codes)
    echo "$input" | sed 's/\x1b\[[0-9;]*m//g'
}

sanitize_and_escape() {
    local sanitized
    sanitized=$(sanitize_input "$1")
    sanitized=$(remove_escape_codes "$sanitized")
    echo "$sanitized"
}


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
            DEFAULT_PROMPT=$(sanitize_and_escape "$OPTARG") ;;
        r) 
            RETURN_TEXT=$(sanitize_and_escape "$OPTARG") ;;
        h) 
            printf "%s\n" "$SCRIPT" "$VERSION" "$COPYRIGHT" "$DESCRIPTION"
            printf "Usage:\n"
            printf "[-p|--prompt] [-t|--timer] [-r|--response] [-h|--help] [-q|--quiet]\n\n"
            printf "    -p, --prompt    [ input required (string must be in quotes) ]\n"
            printf "    -t, --timer     [ number of seconds ]\n"
            printf "    -r, --response  [ requires text (string must be in quotes) ]\n"
            printf "    -h, --help      [ this information ]\n"
            printf "    -q, --quiet     [ quiet text, requires timer to be set. ]\n\n"
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

    local start_time=$(date +%s)  # Get the starting time
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
        read -r -t 0.1 -s key
        if [[ $? -eq 0 ]]; then
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
    local start_time=$(date +%s)  # Get the starting time
    local elapsed_time=0

    while (( LOOP_COUNT > 0 )); do
        # Wait for a key press or use sleep for a short interval
        read -r -t 0.1 -s key
        
        # Check if a key is pressed
        if [[ $? -eq 0 ]]; then
            LOOP_COUNT=0
            break
        fi
        
        # Update elapsed time
        elapsed_time=$(( $(date +%s) - start_time ))
        
        # Only update once per second
        if (( elapsed_time >= 1 )); then
            LOOP_COUNT=$((LOOP_COUNT - 1))  # Decrement
            start_time=$(date +%s)  # Reset the start time
        fi
    if [ $quiet_mode -eq 0 ] ; then 
        printf '\r\033[K'  # Clear the line
        display_time "$LOOP_COUNT"  # Display formatted time
        printf ' %s' "$text_prompt"  # Display the prompt
    fi
    done
    
    printf '\n'  # Move to a new line
    [[ -n $return_prompt ]] && printf '%s\n' "$return_prompt"
}

# Main logic based on quiet and timer flags
if [[ $QUIET_MODE -eq 0 && $TIMER -eq 0 ]]; then
    read -rsn1 -p "$DEFAULT_PROMPT" 
    printf "\n\r"
    exit 0
elif [[ $QUIET_MODE -eq 0 && $TIMER -gt 0 ]]; then
    interrupt "$TIMER" "$DEFAULT_PROMPT"
    [[ -n $RETURN_TEXT ]] && printf '%s\n' "$RETURN_TEXT"  # Print the return text if it exists
    printf "\n\r"
    exit 0
elif [[ $QUIET_MODE -eq 1 && $TIMER -gt 0 ]]; then
    quiet_countdown "$TIMER" "$RETURN_TEXT"  # Call quiet countdown function
    exit 0
elif [[ $QUIET_MODE -eq 1 && $TIMER -eq 0 ]]; then
    printf "Timer must be set.\n\r" 
    exit 1
fi
