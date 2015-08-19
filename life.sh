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

draw 20 20 "`date`"
sleep 3

stty sane
echo '[?25h' # show cursor
