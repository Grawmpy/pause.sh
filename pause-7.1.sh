#!/usr/bin/env bash
# Created: 2025-12-27T23:28Z
# Modified: 2026-01-05T07:35Z
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
#   -a, --allowed   CHARS: Define an allowed list of specific keys.
#   -C, --color     Enable colors (use --help-color for details).
#   -c, --case      Force case-insensitive key matching.
#   -d, --default   CHAR: Set default key for timer expiration.
#   -e, --echo      Print selected key to STDOUT.
#   -h, --help      Show this help text.
#   -l, --log       PATH: Write logs to specified path.
#   -p, --prompt    TEXT: Prompt text displayed to STDERR.
#   -q, --quiet     Suppress all STDERR except response.
#   -r, --response  TEXT: Response text printed to STDERR.
#   -t, --timer     SECONDS: Set countdown duration.
#   -u, --urgent    SECONDS: Set threshold for red timer alert.
#   -v, --version   Show version.
#   -x, --extend    Enable diagnostic messages to STDERR/Log.
#
# Notes:
#    -a, --allowed [only the presented characters (i.e., -ayn, -a yn, -a "yn") will 
#        be selectable if defined.]
#    -d, --default [ONLY applies if -t, --timer is specified otherwise it is ignored.]
#    A monotonic timer is used to prevent time drift and ensure accurate timing even for 
#        long countdowns.
#    All text echoed is sent to STDERR, data to variable is separate and sent to STDOUT.
#    -u, --urgent default is 10 seconds.
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
#
###################################################################################################################################################

set -euE -o noclobber

# Require running from a terminal (no piping/redirection)
if [ ! -t 0 ]; then
    printf '%s\n' "Error: ${0##*/}: Piping not allowed." >&2
    exit 1
fi

# Cleanup: restore terminal to sane defaults and ensure newline
cleanup() {
    printf '\033[K\n' 2>/dev/null || true
    #shellcheck disable=2059
    printf "${SHOW_CURSOR}"
    stty sane 2>/dev/null || true
}

# Trap EXIT and common signals; ERR for failed commands (useful with set -e)
trap cleanup EXIT INT TERM HUP ERR 

stty -echo -icanon

: <<COMMENTS
This software is provided "as-is" without any express or implied warranty. This includes, but is not limited to,
the WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, and NONINFRINGEMENT. In no event shall the 
author(s) and/or copyright holders be held liable for any claim, damages, or other liability, whether in an action 
of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other
dealings in the software. Users are granted the rights to use, modify, and distribute this software at will.
COMMENTS

# ... (Script metadata and help_text) ...
SCRIPT="${0##*/}"
VERSION="7.1.0"

cr=$(printf '\n')

HELP_TEXT="$(cat <<helpText 
Version: ${VERSION}
Copyright (C) 2025 Grawmpy (CSPhelps) <grawmpy@gmail.com> GNU Public License GPL
3.0.

This script [${SCRIPT}] interrupts the current process until either a  countdown
timer reaches zero or the user presses any alphanumeric key, Enter, or Space. If
no timer is  specified,  the  process  remains  interrupted  indefinitely  until
resumed by a key press. When a timer (total seconds) is  provided,  the  process
resumes automatically without user interaction.

Usage:
"${SCRIPT}" [-a, --allowed CHAR] [-C, --color[target][attribute][color]] 
[-c, --case] [-d, --default CHAR] [-e, --echo] [-h, --help] [-l, --log PATH] 
[-p. --prompt TEXT] [-q, --quiet] [-r, --response TEXT] [-t, --timer SECONDS] 
[-u, --urgent SECONDS] [-v, --version] [-x, --extend]

Options:
-a, --allowed   CHARS: Define an allowed list of specific keys.
-C, --color     Enable colors (use --help-color for details).
-c, --case      Force case-insensitive key matching.
-d, --default   CHAR: Set default key for timer expiration.
-e, --echo      Print selected key to STDOUT.
-h, --help      Show this help text.
-l, --log       PATH: Write logs to specified path.
-p, --prompt    TEXT: Prompt text displayed to STDERR.
-q, --quiet     Suppress all STDERR except response.
-r, --response  TEXT: Response text printed to STDERR.
-t, --timer     SECONDS: Set countdown duration.
-u, --urgent    SECONDS: Set threshold for red timer alert.
-v, --version   Show version.
-x, --extend    Enable diagnostic messages to STDERR/Log.

Notes:
    -a, --allowed [only the presented characters (i.e., -ayn, -a yn,  -a  "yn")
    will be selectable if defined.]
    -d, --default [ONLY applies if -t, --timer is  specified  otherwise  it  is
    ignored.]
    A monotonic timer is used to prevent time drift and ensure  accurate  timing
    even for long countdowns.
    All text echoed is sent to STDERR, data to variable is separate and sent  to
    STDOUT.
    -u, --urgent default is 10 seconds.
"${cr}"
helpText
)"

# Color Defaults (Standard ANSI)
BOLD="\033[1m" # bold
UNDERLINE="\033[4m" # underline
BLINK="\033[5m" # blink
RESET="\033[0m" # reset
GREEN="\033[32m" # green
YELLOW="\033[33m" # yellow
BLUE="\033[34m" # blue
MAGENTA="\033[35m" # magenta
CYAN="\033[36m" # cyan
WHITE="\033[37m" # white
RED="\033[31m" # red
BOLD_RED="${BOLD}${RED}" # urgent color (bold red)


display_color_help() {
    # Header
    printf "%bCOLOR CUSTOMIZATION HELP%b\n" "${BOLD}" "${RESET}"
    printf "Usage: -C [target][attribute][color]\n\n"
    
    # Targets Section
    printf "%bTARGETS:%b\n" "${BOLD}" "${RESET}"
    printf "  p : Prompt   t : Timer    r : Response\n\n"
    
    # Attributes & Colors Section
    printf "%bATTRIBUTES:%b\n" "${BOLD}" "${RESET}"
    printf "  1 : %bBold%b  4: %bUnderline%b  5: %bBlink%b\n" "${BOLD}" "${RESET}" "${UNDERLINE}" "${RESET}" "${BLINK}" "${RESET}"
    printf "\n"
    printf "%bCOLORS:%b\n" "${BOLD}" "${RESET}"
    printf "  2 : %bGreen%b     3 : %bYellow%b  4 : %bBlue%b\n"  "${GREEN}" "${RESET}" "${YELLOW}" "${RESET}" "${BLUE}" "${RESET}"
    printf "  5 : %bMagenta%b   6 : %bCyan%b    7 : %bWhite%b\n" "${MAGENTA}" "${RESET}" "${CYAN}" "${RESET}" "${WHITE}" "${RESET}"
    printf "  8 : %bRed%b \n\n" "${RED}" "${RESET}"
    printf "\n"
    printf "  default=${BOLD}${BLUE}%s${RED}%s${GREEN}%s${RESET}\n\n" p14 t18 r12
    
    # Examples Section
    printf "%bEXAMPLES:%b\n" "${BOLD}" "${RESET}"
    printf "  -C p16t8   -> %b%bBold Cyan Prompt%b, %bRed Timer%b\n" "${BOLD}" "${CYAN}" "${RESET}" "${RED}" "${RESET}"
    printf "  -C t13     -> %b%bBold Yellow Timer%b (Defaults for others)\n\n" "${BOLD}" "${YELLOW}" "${RESET}"

    # Informational Footer
    printf "Note: Use %b-u%b to set the ${BOLD}urgent threshold${RESET} in seconds (${BOLD_RED}red text${RESET}).\n" "${BOLD}" "${RESET}"
}

# --- Version detection helpers ---
BASH_MAJOR=${BASH_VERSINFO[0]:-0}
BASH_MINOR=${BASH_VERSINFO[1]:-0}
have_bash_ge() {
  local M=${1:-0} m=${2:-0}
  (( BASH_MAJOR > M )) || (( BASH_MAJOR == M && BASH_MINOR >= m ))
}

# --- Utilities ---
# The countdown utilizes Leading Unit Suppression, displaying a Dynamic Unit 
# format [YYyr:MMmn:DDdy:HH:MM:SS]. As each high-order unit reaches zero, it 
# is dynamically hidden to provide a  cleaner, more readable  display of the 
# remaining time.
display_time() {
    # Build and separate different time sections.
    local ts=${1%.*}
    local years=$((   ts / 31536000 )); ts=$(( ts % 31536000 )) # find years
    local months=$((  ts / 2592000 ));  ts=$(( ts % 2592000 )) # find months
    local days=$((    ts / 86400 ));    ts=$(( ts % 86400 )) # find days
    local hours=$((   ts / 3600 ));     ts=$(( ts % 3600 )) # find hours
    local minutes=$(( ts / 60 )) # find minutes
    local seconds=$(( ts % 60 )) # final seconds

    # Print the time structures
    local out="["
    local active=0
    if (( years > 0 )); then printf -v s "%02dyr:" "${years}"; out+="${s}"; active=1; fi
    if (( active || months > 0 )); then printf -v s "%02dmn:" "${months}"; out+="${s}"; active=1; fi
    if (( active || days > 0 )); then printf -v s "%02ddy:" "${days}"; out+="${s}"; active=1; fi
    if (( active || hours > 0 )); then printf -v s "%02d:"   "${hours}"; out+="${s}"; active=1; fi
    if (( active || minutes > 0 )); then printf -v s "%02d:"   "${minutes}"; out+="${s}"; active=1; fi
    printf -v s "%02d]" "${seconds}"
    printf '%s' "${out}${s}"
}

get_now() {
    # 1. Modern Bash (5.0+) supports EPOCHREALTIME for microsecond precision
    if [[ -n "${BASH_VERSINFO:-}" ]] && (( BASH_VERSINFO[0] >= 5 )) && [[ -n "${EPOCHREALTIME:-}" ]]; then
        printf '%s' "${EPOCHREALTIME}"

    # 2. Bash 4.2+ supports printf builtin for seconds
    elif [[ -n "${BASH_VERSINFO:-}" ]] && { (( BASH_VERSINFO[0] > 4 )) || { (( BASH_VERSINFO[0] == 4 )) && (( BASH_VERSINFO[1] >= 2 )); }; }; then
        printf '%(%s)T' -1

    # 3. macOS Fallback (Bash 3.2 and below)
    # macOS does not have /proc/uptime. Use sysctl to get seconds since boot.
    elif [[ "${OSTYPE}" == "darwin"* ]]; then
        # sysctl returns "kern.boottime: { sec = 1703821234, usec = 0 } ..."
        # We extract the 'sec' value using awk for safety across old versions.
        local boot_sec
        boot_sec=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
        local now_sec
        now_sec=$(date +%s)
        echo $(( now_sec - boot_sec ))

    # 4. Linux Fallback (Bash 2.0+ on systems with /proc)
    elif [ -f /proc/uptime ]; then
        read -r uptime _ < /proc/uptime
        printf '%s' "${uptime}"

    # 5. Final POSIX Fallback
    else
        date +%s
    fi
}

flush_input() {
    # Drain any pending input (non-blocking)
    while IFS= read -rs -t 0.01 -n 1 _ 2>/dev/null; do :; done
}

debug_log() {
    msg=$1
    info=${2:-DEBUG}
    if [[ "${DEBUG}" == true ]]; then
        printf '[ %s ] %s: %s\n' "$(date +'%F %T')" "${info}" "${msg}" >&2
    fi
    if [[ -n "${LOG_FILE}" ]]; then
        printf '[ %s ] %s: %s\n' "$(date +'%F %T')" "${info}" "${msg}" >&2 >> "${LOG_FILE}"
    fi
}

# --- Option mapping for long -> short (works on bash 2.x) ---
OPT_MAP_KEYS="--allow -a --case -c --color -C --default -d --echo -e --help -h --log -l --prompt -p --quiet -q --response -r --timer -t --urgent -u --version -v --extend -x"
map_get() {
    local key="$1"
    local long_opt short_opt
    set -- "${OPT_MAP_KEYS}"
    while (( $# )); do
        long_opt="$1"; short_opt="$2"
        if [[ "${long_opt}" == "${key}" ]]; then
            printf '%s' "${short_opt}"
            return 0
        fi
        shift 2 || break
    done
    return 1
}

# --- Convert long options to short options in ARGS ---
# OPT_MAP_KEYS as before: pairs of long/short
# e.g. OPT_MAP_KEYS="--allow -a --default -d ..." 

# Adaptive long->short option mapper (uses assoc array if available)
if have_bash_ge 4 0; then
    declare -A OPT_MAP
    OPT_MAP["--allow"]="-a"
    OPT_MAP["--case"]="-c"
    OPT_MAP["--color"]="-C"
    OPT_MAP["--default"]="-d"
    OPT_MAP["--echo"]="-e"
    OPT_MAP["--help"]="-h"
    OPT_MAP["--log"]="-l"
    OPT_MAP["--prompt"]="-p"
    OPT_MAP["--quiet"]="-q"
    OPT_MAP["--response"]="-r"
    OPT_MAP["--timer"]="-t"
    OPT_MAP["--urgent"]="-u"
    OPT_MAP["--version"]="-v"
    OPT_MAP["--extend"]="-x"
    OPT_MAP["--help-color"]="-z"

    ARGS=()
    while [[ "$#" -gt 0 ]]; do
        CURRENT_ARG="$1"
        if [[ "${CURRENT_ARG}" == "--" ]]; then
            ARGS+=( -- ); shift
            while [[ "$#" -gt 0 ]]; do ARGS+=( "$1" ); shift; done
            break
        fi

        # --long=val
        if [[ "${CURRENT_ARG}" == --*=* ]]; then
            long="${CURRENT_ARG%%=*}"; val="${CURRENT_ARG#*=}"
            if [[ -n "${OPT_MAP[${long}]:-}" ]]; then
                ARGS+=( "${OPT_MAP[${long}]}" "${val}" )
            else
                ARGS+=( "${CURRENT_ARG}" )
            fi
            shift; continue
        fi

        # --longval (mis-typed)
        if [[ "${CURRENT_ARG}" == --* ]]; then
            if [[ -n "${OPT_MAP[${CURRENT_ARG}]:-}" ]]; then
                ARGS+=( "${OPT_MAP[${CURRENT_ARG}]}" )
            else
                # try prefix split
                found=
                for k in "${!OPT_MAP[@]}"; do
                    if [[ "${CURRENT_ARG}" == "${k}"* && "${CURRENT_ARG}" != "${k}" ]]; then
                        rest="${CURRENT_ARG#"${k}"}"
                        ARGS+=( "${OPT_MAP[${k}]}" "${rest}" )
                        found=1; break
                    fi
                done
                [[ -z "${found}" ]] && ARGS+=( "${CURRENT_ARG}" )
            fi
            shift; continue
        fi

        # -oVALUE for short option that expects arg (split)
        if [[ "${CURRENT_ARG}" == -[!-]* ]]; then
            optchar="${CURRENT_ARG:1:1}"; rest="${CURRENT_ARG:2}"
            case "${optchar}" in
                a|p|r|t|d|l|C|u)
                    if [[ -n "${rest}" ]]; then ARGS+=( "-${optchar}" "${rest}" ); else ARGS+=( "-${optchar}" ); fi
                    shift; continue
                    ;;
                *) ARGS+=( "${CURRENT_ARG}" ); shift; continue ;;
            esac
        fi

        ARGS+=( "${CURRENT_ARG}" ); shift
    done

    set -- "${ARGS[@]}"

else
    # Fallback for bash < 4: use space-separated pairs and map_get()
    OPT_MAP_KEYS="--allow -a --case -c --color -C --default -d --echo -e --help -h --log -l --prompt -p --quiet -q --response -r --timer -t --urgent -u --version -v --extend -x"

    map_get() {
        local key="$1"
        local long_opt short_opt
        set -- "${OPT_MAP_KEYS}"
        while (( $# )); do
            long_opt="$1"; short_opt="$2"
            if [[ "${long_opt}" == "${key}" ]]; then
                printf '%s' "${short_opt}"
                return 0
            fi
            shift 2 || break
        done
        return 1
    }

    ARGS=()
    while [[ "$#" -gt 0 ]]; do
        arg="$1"

        if [[ "${arg}" == "--" ]]; then
            ARGS+=( -- ); shift
            while [[ "$#" -gt 0 ]]; do ARGS+=( "$1" ); shift; done
            break
        fi

        if [[ "${arg}" == --*=* ]]; then
            long="${arg%%=*}"; val="${arg#*=}"
            mapped=$(map_get "${long}") || mapped=""
            if [[ -n "${mapped}" ]]; then ARGS+=( "${mapped}" "${val}" ); else ARGS+=( "${arg}" ); fi
            shift; continue
        fi

        if [[ "${arg}" == --* ]]; then
            mapped=$(map_get "${arg}") || mapped=""
            if [[ -n "${mapped}" ]]; then ARGS+=( "${mapped}" ); shift; continue; fi

            # fuzzy split
            found=
            set -- "${OPT_MAP_KEYS}"
            while (( $# )); do
                longkey="$1"; shortkey="$2"; shift 2
                if [[ "${arg}" == "${longkey}"* && "${arg}" != "${longkey}" ]]; then
                    rest="${arg#"${longkey}"}"
                    ARGS+=( "${shortkey}" "${rest}" )
                    found=1; break
                fi
            done
            if [[ -n "${found}" ]]; then shift; continue; fi

            ARGS+=( "${arg}" ); shift; continue
        fi

        if [[ "${arg}" == -[!-]* ]]; then
            optchar="${arg:1:1}"; rest="${arg:2}"
            case "${optchar}" in
                a|p|r|t|d|l|C|u)
                    if [[ -n "${rest}" ]]; then ARGS+=( "-${optchar}" "${rest}" ); else ARGS+=( "-${optchar}" ); fi
                    shift; continue
                    ;;
                *) ARGS+=( "${arg}" ); shift; continue ;;
            esac
        fi

        ARGS+=( "${arg}" ); shift
    done

    set -- "${ARGS[@]}"
fi

# ... Default initial values ...
ALLOWED=""
ALLOWED_CHARS=()
ECHO_KEY=false
QUIET=false
RESPONSE=""
TIMER=0
DEFAULT_KEY=""
USER_KEY=""
DEBUG=false
LOG_FILE=""
PROMPT="Press [Enter] to continue..."
# Placing the default case sensitivity as on
CASE_INSENSITIVE=false
URGENT_FLAG=false
URGENT_TIME=0
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'
# color default
#COLOR_ARG="p14t18r12" # prompt=bold blue; timer=bold red; response=bold green

get_ansi() {
    # $1 = attribute digit (1=bold, 4=underline, 5=blink, etc.)
    # $2 = color digit (2-8)
    local a c

    # Validate Attribute (Default to 0/Normal if invalid)
    case "$1" in 
        1) a=1 ;; # Bold
        4) a=4 ;; # Underline
        5) a=5 ;; # Blink
        *) a=0 ;; # Reset/Normal
    esac

    # Map your 2-8 digits to actual ANSI foreground codes (30-37)
    case "$2" in 
        2) c=32 ;; # Green
        3) c=33 ;; # Yellow
        4) c=34 ;; # Blue
        5) c=35 ;; # Magenta
        6) c=36 ;; # Cyan
        7) c=37 ;; # White
        8) c=31 ;; # Red
        *) c=32 ;; # Default to Green if unknown
    esac

    # Output the sequence. Using %b in printf interprets \033 correctly.
    # Note: The 'm' at the end is vital; without it, the terminal breaks.
    printf "\033[%s;%sm" "${a}" "${c}"
}

is_valid_timer() {
    local v="$1"
    [[ "${v}" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

# Clear variables at start (You already do this!)
COLOR_P="" COLOR_T="" COLOR_R=""

# Reset for sourcing & define defaults
OPTIND=1
COLOR_P="${BOLD}${BLUE}"   # Default p14
COLOR_T="${BOLD}${RED}"    # Default t18
COLOR_R="${BOLD}${GREEN}"  # Default r12

# Enhanced parsing function
parse_colors() {
    local input="${1:-}"
    [[ -z "$input" ]] && return 0
    
    # Handle help request inside the color string
    if [[ "$input" == *"h"* ]]; then
        show_color_help
        terminate 0
    fi

    local i=0 length=${#input} ch a_digit c_digit used ansi_code
    while [ "$i" -lt "$length" ]; do
        ch="${input:$i:1}"
        case "$ch" in
            p|t|r)
                a_digit="${input:$((i+1)):1}"
                c_digit="${input:$((i+2)):1}"
                
                if [[ "$a_digit" =~ [0-9] ]] && [[ "$c_digit" =~ [0-9] ]]; then
                    ansi_code=$(get_ansi "$a_digit" "$c_digit")
                    used=3
                elif [[ "$a_digit" =~ [0-9] ]]; then
                    ansi_code=$(get_ansi 0 "$a_digit")
                    used=2
                else
                    ansi_code="" # Prevents "disappearing" text if format is invalid
                    used=1
                fi

                case "$ch" in
                    p) COLOR_P="$ansi_code" ;;
                    t) COLOR_T="$ansi_code" ;;
                    r) COLOR_R="$ansi_code" ;;
                esac
                i=$((i + used))
                ;;
            *) i=$((i + 1)) ;;
        esac
    done
}

# --- Parse options with getopts (short options only) ---
while getopts ":a:ep:r:t:Ccd:qxl:u:vhz" opt; do
    case "${opt}" in
        a)  if [[ -z "${OPTARG}" || "${OPTARG}" == -* ]]; then
                debug_log "${SCRIPT} -${opt}: No valid character argument given, found ('${OPTARG}')."
                echo "Error: Option -${opt} requires a valid character argument, not ('${opt}')." >&2
                exit 1
            fi

            ALLOWED="${OPTARG}"
            ALLOWED_CHARS=()
            seen=""  # simple seen-string for bash < 4
            for ((i=0; i<${#ALLOWED}; i++)); do
                ch=${ALLOWED:i:1}
                if [[ "${ch}" =~ [[:alnum:]] ]]; then
                    # membership test in seen (case-sensitive)
                    if [[ "${seen}" != *"${ch}"* ]]; then
                        ALLOWED_CHARS+=( "${ch}" )
                        seen+="${ch}"
                    fi
                fi
            done
            ;;

        c)  CASE_INSENSITIVE=true ; # turns on case insensitivity on allowed characters [-a, --allowed]
            ;;

        C)  NEXT_VAL="${!OPTIND}"

            # If NEXT_VAL is 'h' or contains 'h', show help
            if [[ "$NEXT_VAL" == "h" || "$NEXT_VAL" == *"h"* ]]; then
                show_color_help
                exit 0
            fi

            # Only parse if NEXT_VAL is NOT another flag and NOT empty
            if [[ -n "$NEXT_VAL" && "$NEXT_VAL" != -* ]]; then
                parse_colors "$NEXT_VAL"
                OPTIND=$((OPTIND + 1))
            fi
            export COLOR_P COLOR_T COLOR_R
            # If no argument, the default COLOR_P/T/R (p14, t18, r12) remain
            ;;
        d)  if [[ -z "${OPTARG}" || "${OPTARG}" == -* ]]; then
                debug_log "${SCRIPT} -${opt}: No valid character argument given, found ('${OPTARG}')."
                printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: requires a valid character argument, found ('${OPTARG}')." >&2
                exit 1
            fi
            DEFAULT_KEY="${OPTARG}" 
            ;;

        e)  ECHO_KEY=true 
            ;;

        h)  printf '%s\n' "${HELP_TEXT}"; exit 0 
            ;;

        l)  if [[ -z "${OPTARG}" || "${OPTARG}" == -* ]]; then
                debug_log "${SCRIPT} -${opt}: No valid log filepath argument given, found ('${OPTARG}')."
                printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: requires a valid log filepath argument, found ('${OPTARG}')." >&2
                exit 1
            fi

            LOG_FILE="${OPTARG}"
            LOG_DIR=$(dirname "${LOG_FILE}")

            if [ ! -d "${LOG_DIR}" ]; then
                if ! mkdir -p "${LOG_DIR}"; then
                    debug_log "${SCRIPT} -${opt}: failed to create log directory '${LOG_DIR}'."
                    printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: failed to create log directory '\''${LOG_DIR}'\''." >&2
                    exit 1
                fi
            fi

            if [ -e "${LOG_FILE}" ]; then
                if [ ! -f "${LOG_FILE}" ]; then
                    debug_log "${SCRIPT} -${opt}: path exists but is not a regular file: '${LOG_FILE}'."
                    printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: path exists but is not a regular file: '\''${LOG_FILE}'\''." >&2
                    exit 1
                fi
                if [ ! -w "${LOG_FILE}" ]; then
                    debug_log "${SCRIPT} -${opt}: log file is not writable: '${LOG_FILE}'."
                    printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: log file is not writable: '\''${LOG_FILE}'\''." >&2
                    exit 1
                fi
            else
                if ! : > "${LOG_FILE}" 2>/dev/null; then
                    debug_log "${SCRIPT} -${opt}: failed to create log file '${LOG_FILE}'."
                    printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: failed to create log file '\''${LOG_FILE}'\''." >&2
                    exit 1
                fi
            fi
            ;;

        p)  if [[ -z "${OPTARG}" || "${OPTARG}" == -* ]]; then
                debug_log "${SCRIPT} -${opt}: No valid text argument given, found ('${OPTARG}')."
                printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: No valid text argument given, found ('${OPTARG}')." >&2
                exit 1
            fi
            PROMPT="${OPTARG}" 
            ;;

        q)  QUIET=true 
            ;;

        r)  if [[ -z "${OPTARG}" || "${OPTARG}" == -* ]]; then
                debug_log "${SCRIPT} -${opt}: No valid text argument given, found ('${OPTARG}')."
                printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: No valid text argument given, found ('${OPTARG}')." >&2
                exit 1
            fi
            RESPONSE="${OPTARG}" 
            ;;

        t)  if [[ -z "${OPTARG}" || "${OPTARG}" == -* ]] || !  is_valid_timer "${OPTARG}"; then
                debug_log "${SCRIPT} -${opt}: No valid timer argument given, found ('${OPTARG}')."
                printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: No valid timer argument given, found ('${OPTARG}')." >&2
                exit 1
            fi
            TIMER="${OPTARG}"
            ;;

        u)  URGENT_FLAG=true 
            if [[ -z "${OPTARG}" || "${OPTARG}" == -* ]] || !  is_valid_timer "${OPTARG}"; then
                debug_log "${SCRIPT} -${opt}: No valid timer argument given, found ('${OPTARG}')."
                printf '[  %s  ]: %s\n' "$(date +%Y-%m-%dT%H%M)" "${SCRIPT} -${opt}: No valid timer argument given, found ('${OPTARG}')." >&2
                exit 1
            fi
            URGENT_TIME="${OPTARG}"
            ;;

        v)  printf '%s\n' "${SCRIPT} v.${VERSION}" >&2 ; exit 0 
            ;;

        x)  DEBUG=true 
            ;;

        z)  printf "%bCOLOR CUSTOMIZATION HELP%b\n" "${BOLD}" "${RESET}"
            printf "Usage: -C [target][attribute][color]\n\n"
            printf "%bTARGETS:%b p: Prompt t: Timer r: Response\n" "${BOLD}" "${RESET}"
            printf "%bCOLORS:%b 2:Grn 3:Yel 4:Blu 5:Mag 6:Cyn 7:Whi 8:Red\n" "${BOLD}" "${RESET}"
            exit 0 ;;

        :)  printf '%s\n' "Option ${OPTARG} requires an argument." >&2 ; exit 2 
            ;;

        ?)  printf '%s\n' "Use ${SCRIPT} -h or --help for usage information." >&2 ; exit 1 
            ;;
    esac
done
shift $((OPTIND - 1))

# Usage: log_msg "Text to log" "Label"

debug_log "START TIME" "<---- "
debug_log "Initialized starting values" INFO
if [[ -n "${ALLOWED_CHARS[*]}" ]] ; then 
    debug_log "\"${ALLOWED_CHARS[*]}\"" ALLOWED_CHARS
else debug_log \"all\" "ALLOWED_CHARS"
fi
debug_log "\"${URGENT_FLAG}\"" URGENT_FLAG
debug_log "\"${URGENT_TIME}\"" URGENT_TIME
debug_log "\"${ECHO_KEY}\"" ECHO_KEY
debug_log "\"${TIMER}\"" TIMER
debug_log "\"${DEFAULT_KEY}\"" DEFAULT_KEY
debug_log "\"${QUIET}\"" QUIET
debug_log "\"${DEBUG}\"" DEBUG 
debug_log "\"${PROMPT}\"" PROMPT; 

[[ -n "${RESPONSE}" ]] && debug_log "${RESPONSE}" RESPONSE
[[ -f "${LOG_FILE}" ]] && debug_log "\"$(dirname "${LOG_FILE}")/${LOG_FILE}\"" LOG_FILE

# Process the ALLOWED string AFTER the getopts loop finishes
if [ -n "${ALLOWED}" ]; then
    seen=""
    for ((i=0; i<${#ALLOWED}; i++)); do
        ch=${ALLOWED:i:1}
        if [[ "${ch}" =~ [[:alnum:]] ]]; then
            # Universal fallback for case-normalization (Bash 2.0+)
            check_ch="${ch}"
            if [ "${CASE_INSENSITIVE}" == true ]; then
                check_ch=$(echo "${ch}" | tr '[:upper:]' '[:lower:]')
            fi

            # Membership test
            if [[ "${seen}" != *"${check_ch}"* ]]; then
                ALLOWED_CHARS+=( "${ch}" )
                seen+="${check_ch}"
            fi
        fi
    done
fi

# --- Helpers that must be defined before loop ---
is_allowed_char() {
    local c=$1
    [[ -z "${ALLOWED}" ]] && return 0
    
    local a
    for a in "${ALLOWED_CHARS[@]}"; do
        if [[ "${CASE_INSENSITIVE}" == true ]]; then
            # Use Bash built-in lowercase conversion: ${var,,}
            [[ "${c,,}" == "${a,,}" ]] && return 0
        else
            [[ "${c}" == "${a}" ]] && return 0
        fi
    done
    return 1
}

# --- Start prompt logic ---
flush_input

if [[ "${QUIET}" == false ]]; then
    #shellcheck disable=2059
    printf "${HIDE_CURSOR}" && debug_log "Hiding cursor using ANSI \"\\033[?25l\"" INFO

    # Turn OFF the cursor and display beginning count
    if [[ "${TIMER}" != "0" ]]; then 
        printf "${COLOR_T}%s${RESET} " "$(display_time "${TIMER}")" >&2; 
        printf "${COLOR_P}%s${RESET}" "${PROMPT}"; 
    else
        printf "${COLOR_P}%s${RESET}\n" "${PROMPT}" >&2;  
    fi

fi

# choose scale consistent with INCR_DEN; using milliseconds (100) here
SCALE=1000
# If you change any of the scale, add same number of zeroes to the code inside to_scaled_int as well
START=$(get_now)

# convert a decimal time string to integer scaled units (centiseconds)
to_scaled_int() {
    local ts="$1"
    local intpart=${ts%%.*}
    local fracpart=${ts#*.}
    if [[ "${fracpart}" == "${ts}" ]]; then
        fracpart="000"
    else
        # normalize fracpart to exactly two digits (centiseconds)
        if (( ${#fracpart} >= 2 )); then
            fracpart=${fracpart:0:2}
        else
            fracpart="${fracpart}"0
        fi
    fi
    # ensure decimal digits are numeric (avoid leading zero confusion)
    printf '%d\n' $(( intpart * SCALE + 10#"${fracpart}" ))
}

START_SCALED=$(to_scaled_int "$START")
LAST_DISPLAYED=-1
USER_KEY=""

while true; do
    CURRENT_TIME=$(get_now)
    if [[ "${QUIET}" == false ]]; then printf '\e[?25l'; fi

    CURRENT_SCALED=$(to_scaled_int "$CURRENT_TIME")

    ELAPSED_SCALED=$(( CURRENT_SCALED - START_SCALED ))
    if (( ELAPSED_SCALED < 0 )); then ELAPSED_SCALED=0; fi

    # convert TIMER (decimal) to scaled integer once (can be cached)
    TIMER_SCALED=$(to_scaled_int "${TIMER}")

    REMAIN_SCALED=$(( TIMER_SCALED - ELAPSED_SCALED ))
    if (( REMAIN_SCALED < 0 )); then REMAIN_SCALED=0; fi

    # For display, convert remaining centiseconds to whole seconds.
    # Round up so display doesn't flicker to 0 prematurely.
    REMAIN_INT=$(( (REMAIN_SCALED + (SCALE - 1)) / SCALE ))

    (( REMAIN_INT <= URGENT_TIME )) && COLOR_T="${BOLD}${RED}"
    if [[ "${QUIET}" == false && "${TIMER}" != "0" && "${REMAIN_INT}" -ne "${LAST_DISPLAYED}" ]]; then
        printf "${COLOR_T}\e[K\r%s${RESET} ${COLOR_P}%s${RESET}" "$(display_time "${REMAIN_INT}")" "${PROMPT}" >&2
        LAST_DISPLAYED="${REMAIN_INT}"
    fi

    (( REMAIN_INT <= URGENT_TIME )) && COLOR_T="${BOLD}${RED}"
    # finished check: ELAPSED >= TIMER  (compare scaled ints)
    if [[ "${TIMER}" != "0" && "${ELAPSED_SCALED}" -ge "${TIMER_SCALED}" ]]; then
        USER_KEY="${DEFAULT_KEY}"
        [[ "${QUIET}" == false ]] && printf "\r${COLOR_T}%s${RESET}\e[K\e[?25h${COLOR_P}%s${RESET}\n" "[00]" "${PROMPT}" >&2
        break
    fi

    # Non-blocking read unchanged
    if LC_ALL=C IFS= read -rsn1 -t 0.1 char 2>/dev/null; then
        case "${char}" in
            [A-Za-z0-9]|" "|"")
                # Only proceed if the character is allowed
                if is_allowed_char "${char}"; then
                    if [[ -z "${char}" ]]; then USER_KEY="ENTER"
                    elif [[ "${char}" == " " ]]; then USER_KEY="SPACE"
                    else USER_KEY="${char}"
                    fi
                    break
                fi
                ;;
        esac
    fi
done

[[ "${ECHO_KEY}" == true && -n "${USER_KEY}" ]] && { 
    printf '%s\n' "${USER_KEY}" >&1
    debug_log "Default Key: [${DEFAULT_KEY}]; User Key: [${USER_KEY}]" INFO
}

[[ "${DEBUG}" == true && "${ECHO_KEY}" == true && -n "${USER_KEY}" ]] && { 
    debug_log "Key press detected: ${USER_KEY}" FINAL
}

# To turn ON the cursor
#shellcheck disable=2059
printf "${SHOW_CURSOR}" && debug_log "Reshowing cursor using ANSI \"\\e[?25h\"" INFO

# Debug prefix (No newline)
[[ -n "${RESPONSE}" ]] && printf "${COLOR_R}%s${RESET}\n" "${RESPONSE}" >&2 
