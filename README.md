# pause.sh
Pure bash pause script that interrupts a program until either the user presses any numeric or symbol key, or the 
optional timer (-t, --timer) reaches 00. Interupt is indefinite and requires user input to continue without timer option.
Optional prompt text entry (-p, --prompt) and response text (-r, --response) entry allow for customization. 
Quiet mode available for timer with no text output. Default is no timer and no response after keypress.
Default prompt is "Press any key to continue..."

Shellcheck verified.

Binary available of this script: https://github.com/Grawmpy/pause.sh/releases

    $ ./pause.sh [-p|--prompt ] [-t|--timer ] [-r|--response ] [-h|--help] [-q|--quiet ] 

    -p, --prompt    [ input required (string must be in quotes) ]
    -t, --timer     [ number of seconds ]
    -r, --response  [ requires text (string must be in quotes) ]
    -h, --help      [ this information ]
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
    
    Input:  $ ./pause -p \"Optional Prompt\" -r \"[ Your response ]\" -t <seconds>
    Output: $ [timer] Optional Prompt
            $ [ Your Response ]
            $
    
    [ seconds are converted to 00h:00m:00s style format ]
