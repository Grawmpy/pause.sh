# pause.sh

Current release: https://github.com/Grawmpy/pause.sh/releases

This utility is a high-precision synchronous process  interrupter  designed  for
secure Linux environments. It features Monotonic Timing  Accuracy  via  internal
shell parameters to  eliminate  cumulative  drift  during  extended  countdowns.
Security is  maintained  through  Mandatory  TTY  Validation  and  Strict  Input
Sanitization, which renders all incoming  ANSI  escape  sequences  as  literals,
mitigating potential side-channel attacks on the host terminal session.

Core Functionality: Asynchronous Event Handling

The utility operates as a Synchronous Blocking Process,  suspending  the  parent
thread until termination criteria are met. Execution resumes upon the  detection
of a Non-Escape Character Input  (defined  via  the  -a  whitelist  or  standard
Alphanumeric/Space/Return) or the expiration of the optional Monotonic Countdown
Timer. New Feature: Granular ANSI Color Customization (-C)

Version 7.1 introduces a  Tri-Zone  ANSI  Rendering  Engine.  Users  can  define
distinct visual attributes for the Prompt, Timer, and Response strings  using  a
compact tokenized syntax:

    * Targeting: p (Prompt), t (Timer), and r (Response).
    * Attributes: Bold (1), Underline (4), or Blink (5).
    * Spectrum: 8-bit color mapping (Green, Yellow, Blue, Magenta, Cyan,  White,
      Red).
    * Urgent Thresholding (-u): Integrates with the Timer  logic  to  trigger  a
      State-Change Alert,  automatically transitioning the display  to Bold  Red 
      when the countdown falls below a user-defined second threshold.

New Feature: Persistent Audit Logging (-l)

For automated environments, the utility  now  supports  Atomic  Stream  Mirrored
Logging. Using the -l flag, the process generates a persistent  audit  trail  of
start times,  termination  triggers  (key-press  vs.  timeout),  and  diagnostic
heartbeats. The utility includes Recursive Directory Provisioning, automatically
creating the necessary path hierarchy for log residency.

New Feature: Input Whitelisting & Case Sensitivity (-a, -c)

    Key Whitelisting: The -a  flag  enforces  Input  Restriction,  ignoring  all
    keystrokes except those explicitly defined in the allowed  character  array.
    Case Orthogonality: By default,  input  is  case-sensitive.  The  -c  toggle
    enables  Normalized  Comparison,  allowing  lowercase  inputs   to   satisfy
    uppercase requirements, essential for high-speed data entry environments.

Security Hardening & Diagnostic Extension (-x)

    Diagnostic Mode (-x): Enables Verbose State-Tracking.  Diagnostic  messages,
    including TTY status, sanitized string length, and clock-drift  corrections,
    are routed  to  STDERR  or  the  defined  log  file  to  ensure  operational
    transparency without polluting the primary STDOUT pipe.

    Escape Sequence Neutralization: All  string-based  arguments  undergo  Recursive
    Sanitization.  The  utility  literalizes  all  ASCII  control   characters   and
    explicitly strips the ESC (\x1b) character to mitigate Terminal Escape Injection
    (TEI) vulnerabilities.

CLI Flag Reference

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

Granular Interface Customization: The -C Logic Engine

The utility implements a Positional Token Parser for visual styling. The -C flag
accepts a composite string  that  defines  the  aesthetics  for  three  distinct
interface zones. Each customization token follows  a  [Target][Attribute][Color]
schema.

    1. Target Identifiers

        p : Primary Prompt (The instruction text).
        t : Countdown Timer (The clock display).
        r : Key Response (The character echo upon termination).

    2. Attribute Mapping

        1 : Bold (High Intensity)
        4 : Underline
        5 : Blink (Terminal-emulator dependent)
        0 : Normal (Standard weight)

    3. Color Spectrum (ANSI Foreground)
    Code	Color	 |   Code	Color
    2	    Green	 |   6	    Cyan
    3	    Yellow	 |   7	    White
    4	    Blue	 |   8	    Red
    5	    Magenta	 |	

Example Tokenization:

    -C p14 : Sets Prompt to Bold Blue.
    -C t18r12 : Sets Timer to Bold Red and Response to Bold Green.
    -C h : Invokes the internal Attribute Map for real-time reference.

Default Configuration:

If the -C flag  is  invoked  without  arguments,  the  utility  initializes  the
Standard Tactical Profile: p14 (Bold Blue Prompt), t18 (Bold Red Timer), and r12
(Bold Green Response).

HELP TEXT:

      Copyright (C) 2025 Grawmpy (CSPhelps) <grawmpy@gmail.com> GNU Public License GPL
      3.0.

      This script [pause] interrupts the current process until either a  countdown
      timer reaches zero or the user presses any alphanumeric key, Enter, or Space. If
      no timer is  specified,  the  process  remains  interrupted  indefinitely  until
      resumed by a key press. When a timer (total seconds) is  provided,  the  process
      resumes automatically without user interaction.
      
      Usage:
      pause [-a, --allowed CHAR] [-C, --color[target][attribute][color]] 
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
          -a, --allowed [only the presented characters (i.e., -ayn, -a yn,  -a  "yn") will be selectable if defined.]
          -d, --default [ONLY applies if -t, --timer is specified otherwise it is ignored.]
          A monotonic timer is used to prevent time drift and ensure  accurate  timing even for long countdowns.
          All text echoed is sent to STDERR, data to variable is separate and sent  to STDOUT.
          -u, --urgent default is 10 seconds.
