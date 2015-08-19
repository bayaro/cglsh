#!/bin/bash

function draw() {
    echo -n "[$1;${2}H" # set cursor position
    echo -n "$3" # show string
    echo -n '[?25l' # hide cursor
}

function bye_bye() {
    stty sane
    echo '[?25h' # show cursor
}

trap bye_bye SIGINT SIGTERM INT EXIT

stty raw -echo
echo -n 'c' # VT100 reset
echo '[?71' # turn off auto-wrap
echo '' # clear screen
echo -n '[?25l' # hide cursor

AGE=10
while [ $AGE -gt 0 ] ; do
    draw 20 20 "AGE: $AGE"

    sleep 1
    if [ "`dd bs=1 count=1 iflag=nonblock status=none 2>/dev/null`" == "" ]; then # stop on ^C
        break
    fi
    AGE=$(( $AGE - 1 ))
done
