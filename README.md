# pause.sh

Current release: https://github.com/Grawmpy/pause.sh/releases

Have .deb install file, standard binary that is in the .deb file and the bash script the previous two are based on.
Pure bash pause script that interrupts a program until either the user presses any numeric or symbol key, or the 
optional timer (-t, --timer) reaches 00. It works similarly to the one included with windows with a couple extra 
options. The interupt is indefinite and requires user input to continue without timer option by pressing any key but SHIFT.
Optional prompt text entry (-p, --prompt) and response text (-r, --response) entry allow for customization. 
Quiet mode available for timer with no text output. Default is no timer and no response after keypress.
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
