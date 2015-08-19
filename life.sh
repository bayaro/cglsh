#!/bin/bash

ROWS=`stty -a | grep rows | sed -r 's/.*rows ([0-9]+);.*/\1/'`
COLS=`stty -a | grep columns | sed -r 's/.*columns ([0-9]+);.*/\1/'`

STATUSROW=$ROWS
ROWS=$(( $ROWS - 1 )) # last rows will be used as status line

MAX_GEN=10 # max generations count
MAP_SIZE=$(( $ROWS * $COLS ))
INITIAL_POP_SIZE=$(( $MAP_SIZE / 10 ))

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
    # msg & msg_length are not local, they will be used to hide old status on next step
    msg=`printf "%-${msg_length}s" ""`
    draw $STATUSROW $(( $COLS - $msg_length - 1 )) "$msg" CLEAR
    msg="MAP: ${COLS}x${ROWS} POPULATION: ${#POP[@]} GEN: $GEN"
    msg_length=${#msg}
    draw $STATUSROW $(( $COLS - $msg_length - 1 )) "$msg" CYAN
}

function init_population() {
    local O
    local C
    local R
    local i
    for (( i = 0; i < $INITIAL_POP_SIZE; i++ )); do
        O=$(( RANDOM % $MAP_SIZE ))
        C=$(( $O % $COLS + 1 ))
        R=$(( ( $O - $C ) / $COLS + 1 ))
        while [ "x${POP[$C,$R]}" != "x" ]; do # add creature to next pos if current is busy
            O=$(( ( $O + 1 ) % $MAP_SIZE + 1 ))
            C=$(( $O % $COLS ))
            R=$(( ( $O - $C ) / $COLS + 1 ))
        done
        POP[$C,$R]=$C,$R
    done
}

function draw_population() {
    local C
    local R
    local i
    for i in "${POP[@]}"; do
        C=${i%%,*}
        R=${i##*,}
        draw $R $C '0' _RED
    done
}

# with this function we can in future get not only neigbours of 1st level but also 2nd, 3rd, etc :)
function check_neigbours() {
    local CC=$1
    local RR=$2
    local C
    local R
    local has_neig_count
    NEIG_COUNT=-1 # to avoid calculation current cell as neighbor of self
    for (( C = $(( $CC - 1 )); C <= $(( $CC + 1 )); C++ )); do
        for (( R = $(( $RR - 1 )); R <= $(( $RR + 1 )); R++ )); do
            if [ "x${POP[$C,$R]}" == "x" ]; then 
                # empty cell, mark it as have +1 neighbor
                has_neig_count=${EMPTYMAP[$C,$R]}
                if [ "x$has_neig_count" == "x" ]; then has_neig_count=0; fi
                EMPTYMAP[$C,$R]=$(( $has_neig_count + 1 ))
            else
                # non empty, increase count of neigbours
                NEIG_COUNT=$(( $NEIG_COUNT + 1 ))
            fi
        done
    done
}

########################################################################################
#     main()
########################################################################################

declare -A POP
declare -A EMPTYMAP
init_population

trap bye_bye SIGINT SIGTERM INT EXIT

stty raw -echo
echo -n 'c' # VT100 reset
echo '[?71' # turn off auto-wrap
echo '' # clear screen
echo -n '[?25l' # hide cursor

GEN=1
while [ $MAX_GEN -gt $GEN ] ; do
    draw_population
    draw_status

    #sleep 1
    #if [ "`dd bs=1 count=1 iflag=nonblock status=none 2>/dev/null`" == "" ]; then # stop on ^C
    if [ "`dd bs=1 count=1 status=none 2>/dev/null`" == "" ]; then # stop on ^C
        break
    fi
    GEN=$(( $GEN + 1 ))
done

