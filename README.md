# pause.sh

Current release: https://github.com/Grawmpy/pause.sh/releases

Have .deb install file, standard binary that is in the .deb file and the bash script the previous two are based on.
The program will echo "Press any key to continue..." when called indefinitely until either any key but [Shift] is pressed, or the optional timer [--t | --timer] reaches zero. Timer is shown in [00:00:00] format. The program allows for quiet running with no prompt, just a pause with cursor blink [-q | --quiet] that also must have a timer set in order to run in quiet mode. There is an option to place an alternative prompt which replaces the default prompt with your own [-p | --prompt ,(Must be within double quotes)] and then there is the ability to also add an echoed response to the output [-r | --response (Must be within double quotes)].


Default prompt is "Press any key to continue..."

    $ ./pause.sh [-p|--prompt ] [-t|--timer ] [-r|--response ] [-h|--help] [-q|--quiet ] 

    -p, --prompt    [ text string required (string must be in quotes)  ]
    -t, --timer     [ number of seconds ]
    -r, --response  [ text string required (string must be in quotes)  ]
    -h, --help      [ help information ]
    -q, --quiet     [ quiets text, requires timer be set. ]

    Examples:
    Input:  $ ./pause.sh
    Output: $ Press any key to continue...
            $
    
    Input:  $ ./pause.sh --timer <seconds>
    Output: $ [timer] Press any key to continue...
            $
    
    Input:  $ ./pause --prompt "Optional Prompt" --response "Your response"
    Output: $ Optional Prompt
            $ Your Response
            $
    
    Input:  $ ./pause -p "Optional Prompt" -r "[ Your response ]" -t <seconds>
    Output: $ [timer] Optional Prompt
            $ [ Your Response ]
            $
    [format of time will be 00:00:00]
