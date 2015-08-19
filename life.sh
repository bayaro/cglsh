#!/bin/bash

function draw() {
    echo -n "[$1;${2}H" # set cursor position
    echo -n "$3" # show string
    echo -n '[?25l' # hide cursor
}

stty raw
echo -n 'c' # VT100 reset
echo '[?71' # turn off auto-wrap
echo '' # clear screen
echo -n '[?25l' # hide cursor

AGE=3
while [ $AGE -gt 0 ] ; do
    draw 20 20 "AGE: $AGE"

    sleep 1
    AGE=$(( $AGE - 1 ))
done

stty sane
echo '[?25h' # show cursor
