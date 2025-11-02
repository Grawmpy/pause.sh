# pause.sh

Current release: https://github.com/Grawmpy/pause.sh/releases

The program will echo "Press any key to continue...", when called, indefinitely until either the user presses any key but [Shift], or the optional timer 
[--t | --timer] reaches zero. Timer is shown in [00:00:00] format and hides as it reaches zero. The program allows for quiet running with no prompt, just 
a pause with cursor blink [-q | --quiet] that must have a timer set as well. There is an option to place an alternative pause prompt which replaces the default with your own [-p | --prompt ,(Must be within double quotes)] and the ability to also add response text to the output [-r | --response (Must be within double quotes)].

When I migrated to Linux from Windows/DOS, I was rather surprised that there wasn't some type of "pause" function of any sort within the basic functioning of Linux. I have tried to make this as close to pure bash as possible in every directive I used. I have also spent many hours trying very hard to get the time function on the countdown to be as accurate as possible using different sources but unfortunately there is no way to get the precision I was hoping for through simple bash. I wanted a function in bash where I could just give the command "pause" and it would pause and I have done that with a little extra.

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

    Note: quiet mode (-q|--quiet) will hide all output except response (-r|--response) text, if given, until contiuation of process.
