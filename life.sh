#!/bin/bash

GENERATIONS=10 # max generations count

ROWS=`stty -a | grep rows | sed -r 's/.*rows ([0-9]+);.*/\1/'`
COLS=`stty -a | grep columns | sed -r 's/.*columns ([0-9]+);.*/\1/'`

STATUSROW=$ROWS
ROWS=$(( $ROWS - 1 )) # last rows will be used as status line

BLACK='[38m'
GREY='[1;30m'
RED='[1;31m'
GREEN='[1;32m'
YELLOW='[1;33m'
BLUE='[1;34m'
MAGENTA='[1;35m'
CYAN='[1;36m'
WHITE='[1;37m'

OFF='[0m'
FILL='[7m'
CLEAR='[39m[49m'

iBLACK='[38m'
iGREY='[0;30m'
iRED='[0;31m'
iGREEN='[0;32m'
iYELLOW='[0;33m'
iBLUE='[0;34m'
iMAGENTA='[0;35m'
iCYAN='[0;36m'
iWHITE='[0;37m'

# background
_BLACK='[1;30m'
_RED='[1;41m'
_GREEN='[1;42m'
_YELLOW='[1;43m'
_BLUE='[1;44m'
_MAGENTA='[1;45m'
_CYAN='[01;46m'
_WHITE='[1;47m'

function bye_bye() {
    stty sane
    draw $ROWS $COLS ""
    echo '[?25h' # show cursor
}

function draw() {
    local color
    if [ -z "$4" ]; then
        color=WHITE
    else
        color=$4
    fi
    eval color=\"\$$color\"
    echo -n "[$1;${2}H" # set cursor position
    echo -n "$color"
    echo -n "$3" # show string
    echo -n '[?25l' # hide cursor
}

function draw_status() {
    msg=`printf "%-${msg_length}s" ""`
    draw $STATUSROW $(( $COLS - $msg_length - 1 )) "$msg" CLEAR
    msg="GENERATIONS LEFT: $GENERATIONS"
    msg_length=${#msg}
    draw $STATUSROW $(( $COLS - $msg_length - 1 )) "$msg" CYAN
}

########################################################################################
#     main()
########################################################################################

trap bye_bye SIGINT SIGTERM INT EXIT

stty raw -echo
echo -n 'c' # VT100 reset
echo '[?71' # turn off auto-wrap
echo '' # clear screen
echo -n '[?25l' # hide cursor

while [ $GENERATIONS -gt 0 ] ; do
    draw_status

    sleep 1
    if [ "`dd bs=1 count=1 iflag=nonblock status=none 2>/dev/null`" == "" ]; then # stop on ^C
        break
    fi
    GENERATIONS=$(( $GENERATIONS - 1 ))
done

GENERATIONS=0
draw_status
