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
#  I've added are ones I would have liked to have seen included and easily accessible
#  from a simple option passed to the command. This is my best attempt to add those same features
#  I felt were major deficiencies and should have been added to the pause program. I know some would 
#  argue that this script is a bit superfluous and not really needed. In a way you're right, you can
#  add a few lines to do what all I do here but why do all that when you can simple use the command "pause" and 
#  and have built-in options to customize it without having to do the coding yourself.

#  Command: pause
#  Options: [-p|--prompt] [-r|--response] [-t|--timer] [-q|--quiet] [-h|--help]
#  pause ( without any options)
#  $ Press any key to continue...
#
#  Options include (No spaces needed between options and values):
#  [--prompt, -p] (prompt text must be inside double quotes, example: pause -p "Hello World", or pause --prompt "Hello World")
#  [--response, -r ] (response text must be inside double quotes, example: pause -r "Continuing...", or pause --response "Continuing...")
#  [--timer, -t ] (Must be in total seconds. Example: pause -t 30, or pause --timer 30)
#  [--quiet, -q ] (No prompt, just cursor blink. Timer required to be set for use. Example: pause -q -t 10, or pause --quiet --timer 10, or pause -qt10)
#  Order of options does not matter as they are processed when they are encountered and used later in the main logic.

#  1. I wanted the script to have a way to change the default prompt to a custom text to accommodate for the needs of the user. 
#  2. I wanted a way to use a custom response, if needed, echoed after the process continued. 
#  3. I wanted a quiet countdown that could pause a process for a set time to wait for whatever reason with no prompt (interruptable with keypress).
#     This one I mostly use for forcing a pause in the program to slow things down without user interaction. Sleep is a similar function.
#  4. I wanted an easy way to use a countdown timer. This is not meant to be super accurate but I tried to keep the
#     lag time to a minimum. It does have a little lag time so over time it will lose accuracy. The extended time
#     separation was simply for fun. I added the countdown in years, months, days, and finally the hours, minute and seconds displayed as [00:00:00].
#     Each section disappears as the countdown reaches zero. Format: [YEAR:MONTH:DAY:HOUR:MINUTE:SECOND]. 
#     Format for display is: [01yr:01mn:01dy:01:01:00], each section disappearing at 00 until only the [00] remains.
#  5. I wanted to make sure that only an alphanumeric key the user pressed closed the pause script and continued the process.
#     I tried to eliminate the function, arrow, shift, ctrl or alt keys being recognized to continue the process. 
#     I wanted it to be functional for use in passing on the character pressed to be used anywhere the capture of 
#     a single alphanumeric key press is needed.
#  6. I wanted to use as pure bash as possible to allow for maximum usage and broad compatibility .
#  

#  Copyright: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
#  SOFTWARE. GPL.3.0
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################

# Variables
DEFAULT_PROMPT="Press any key to continue..."
SCRIPT="${0##*/}"
RETURN_TEXT=""
TIMER=0
QUIET_MODE=0
COPYRIGHT="GPL3.0 License. Software is intended for free use only."
DESCRIPTION="A simple script that interrupts the current process until user presses key or optional timer reaches 00. Format is [HH:MM:SS"

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
            printf "Examples:\n (Timer will count down to zero)"
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

# Function to display the countdown timer in the desired format
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
    [[ $months -gt 0 || $years -gt 0 ]] && printf '%02dmn:' "$months"
    [[ $days -gt 0 || $months -gt 0 ]] && printf '%02ddy:' "$days"
    [[ $hours -gt 0 || $days -gt 0 ]] && printf '%02d:' "$hours"
    [[ $minutes -gt 0 || $hours -gt 0 ]] && printf '%02d:' "$minutes"
    printf '%02d]' "$seconds"
}

# Function for the quiet countdown
quiet_countdown() {
    local LOOP_COUNT="$1"
    local return_prompt="$2"
    local status
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
        read -r -t 0.1 ; status=$?
        if [[ ${status} -eq 0 ]]; then
            LOOP_COUNT=0  # Exit countdown if a key is pressed
        fi
    done

    # After countdown is finished
    printf '\r'   # return to beginning of line
    if [[ -n $return_prompt ]]; then 
        printf '%s\n' "$return_prompt"  # Print the return prompt if provided
    fi
}

interrupt() {
    local LOOP_COUNT="$1" # Timer count in number of seconds
    local text_prompt="$2" # Prompt value
    local return_prompt="$3" # Response value
    local quiet_mode=${QUIET_MODE} # Quiet mode: (1|0)
    local start_time=$(date +%s) # Get the seconds in date for comparison

    printf "\e[?25l" # hide cursor
    # Print initial line once
    printf '\r'  # Go to column 0
    display_time "$LOOP_COUNT" # Start the countdown timer
    printf ' %s' "$text_prompt" # write the beginning value to the screen

    while (( LOOP_COUNT > 0 )); do
        read -r -t 0.1 ; status=$? # check for keypress but don't write to tty
        if [[ ${status} -eq 0 ]]; then LOOP_COUNT=0; break; fi # if keypress detected break from script
        
        # Compare time to make sure second has passed. More accurate than simple 1 second delay.
        if (( $(date +%s) - start_time >= 1 )); then
            LOOP_COUNT=$((LOOP_COUNT - 1))
            start_time=$(date +%s)
            printf '\r'
            display_time "$LOOP_COUNT"
            printf ' %s' "$text_prompt"
        fi
    done
    
    #printf "\e[?25h\n" # show cursor, line return
    printf "\r\033[K" # Return cursor and clear the line to the end
    [[ -n $return_prompt ]] && printf '%s\r' "$return_prompt"
}


# Main logic based on quiet and timer flags
# quiet=no, timer=no
if [[ $QUIET_MODE -eq 0 && $TIMER -eq 0 ]]; then
    read -rsn1 -p "$DEFAULT_PROMPT" 
    printf "\n"
    exit 0
# quiet=no, timer=yes
elif [[ $QUIET_MODE -eq 0 && $TIMER -gt 0 ]]; then
    printf "\e[?25l" # hide cursor
    interrupt "$TIMER" "$DEFAULT_PROMPT"
    printf "\e[?25h" # return/show cursor
    [[ -n $RETURN_TEXT ]] && printf '%s\n' "$RETURN_TEXT"  # Print the return text if it exists
    exit 0
# quiet=yes, timer=no
elif [[ $QUIET_MODE -eq 1 && $TIMER -eq 0 ]]; then
    printf "Timer must be set.\n" 
    exit 1
# quiet=yes, timer=yes
elif [[ $QUIET_MODE -eq 1 && $TIMER -gt 0 ]]; then
    printf "\e[?25h" # return/show cursor
    quiet_countdown "$TIMER" "$RETURN_TEXT"  # Call quiet countdown function
    exit 0
fi
