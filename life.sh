#!/bin/bash

stty raw
echo -n 'c' # VT100 reset
echo '[?71' # turn off auto-wrap
echo '' # clear screen
echo -n '[?25l' # hide cursor
sleep 3
stty sane
echo '[?25h' # show cursor
