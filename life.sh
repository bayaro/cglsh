#!/bin/bash

ROWS=`stty -a | grep rows | sed -r 's/.*rows ([0-9]+);.*/\1/'`
COLS=`stty -a | grep columns | sed -r 's/.*columns ([0-9]+);.*/\1/'`

STATUSROW=$ROWS
ROWS=$(( $ROWS - 1 )) # last rows will be used as status line

MAX_GEN=-1 # max generations count
MAP_SIZE=$(( $ROWS * $COLS ))
INITIAL_POP_SIZE=$(( $MAP_SIZE / 10 ))

GREY='[1;30m'
RED='[1;31m'
GREEN='[1;32m'
YELLOW='[1;33m'
BLUE='[1;34m'
MAGENTA='[1;35m'
CYAN='[1;36m'
WHITE='[1;37m'
BLACK='[1;38m'
CLEAR='[39m'

iGREY='[0;30m'
iRED='[0;31m'
iGREEN='[0;32m'
iYELLOW='[0;33m'
iBLUE='[0;34m'
iMAGENTA='[0;35m'
iCYAN='[0;36m'
iWHITE='[0;37m'
iBLACK='[0;38m'

# background
_GREY='[40m'
_RED='[41m'
_GREEN='[42m'
_YELLOW='[43m'
_BLUE='[44m'
_MAGENTA='[45m'
_CYAN='[46m'
_WHITE='[47m'
_BLACK='[48m'
_CLEAR='[49m'

function hello() {
	stty raw -echo
	echo -n 'c' # VT100 reset
	echo '[?71' # turn off auto-wrap
	echo '' # clear screen
	echo -n '[?25l' # hide cursor
}

function bye_bye() {
	stty sane
	draw $ROWS $COLS ""
	echo '[?25h' # show cursor
}

function draw() {
	echo -n "[$1;${2}H" # set cursor position
	if [ "x$4" != "x" ]; then
		echo -n "$4"
	fi
	echo -n "$3" # show string
	echo -n '[?25l' # hide cursor
}

function draw_status() {
	# msg & msg_length are not local, they will be used to hide old status on next step
	msg=`printf "%-${msg_length}s" ""`
	draw $STATUSROW $(( $COLS - $msg_length - 1 )) "$msg" $_CLEAR$CLEAR
	msg="MAP: ${COLS}x${ROWS} POPULATION: ${#POP[@]} GEN: $GEN"
	msg_length=${#msg}
	draw $STATUSROW $(( $COLS - $msg_length - 1 )) "$msg" $CYAN
}

function draw_population() {
	if [ -z "$1" ]; then
		echo -n $_RED$WHITE
	else
		echo -n $1
	fi
	local C
	local R
	local i
	for i in "${!POP[@]}"; do
		C=${i%%,*}
		R=${i##*,}
		draw $R $C ${POP[$i]}
	done
}

function draw_dead {
	if [ -z "$1" ]; then
		echo -n $_CLEAR$GREEN
	else
		echo -n $1
	fi
	local C
	local R
	local i
	for i in "${!DEAD[@]}"; do
		C=${i%%,*}
		R=${i##*,}
		draw $R $C ${DEAD[$i]}
	done
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
		POP[$C,$R]=0
	done
}

# with this function we can in future get not only neigbours of 1st level but also 2nd, 3rd, etc :)
function check_neigbours() {
	local MiR=$(( $1 - 1 ))
	if [ $MiR -lt 1 ]; then MiR=1; fi
	local MaR=$(( $1 + 1 ))
	if [ $MaR -gt $ROWS ]; then MaR=$ROWS; fi
	local MiC=$(( $2 - 1 ))
	if [ $MiC -lt 1 ]; then MiC=1; fi
	local MaC=$(( $2 + 1 ))
	if [ $MaC -gt $COLS ]; then MaC=$COLS; fi
	local C
	local R
	local has_neig_count
	for (( C = $MiC; C <= $MaC; C++ )); do
		for (( R = $MiR; R <= $MaR; R++ )); do
			if [ "x${POP[$C,$R]}" == "x" ]; then
				# empty cell, mark it as have +1 neighbor
				has_neig_count=${TOBEBURN[$C,$R]}
				TOBEBURN[$C,$R]=$(( $has_neig_count + 1 ))
			else
				# non empty, increase count of neigbours
				NEIG_COUNT=$(( $NEIG_COUNT + 1 ))
			fi
		done
	done
}

function check_population() {
	local C
	local R
	local i
	TOBEBURN=
	declare -A TOBEBURN
	NEW_NCOUNT=
	declare -A NEW_NCOUNT
	for i in "${!POP[@]}"; do
		C=${i%%,*}
		R=${i##*,}
		NEIG_COUNT=0
		check_neigbours $R $C
		if [ $NEIG_COUNT -eq 3 ] || [ $NEIG_COUNT -eq 4 ]; then
			NEW_NCOUNT[$i]=$(( $NEIG_COUNT - 1 ))
		else
			DEAD[$i]=$(( $NEIG_COUNT - 1 ))
		fi
	done
	for i in "${!DEAD[@]}"; do
		unset POP[$i]
	done
	for i in "${!NEW_NCOUNT[@]}"; do
		POP[$i]=${NEW_NCOUNT[$i]}
	done
	for i in "${!TOBEBURN[@]}"; do
		if [ ${TOBEBURN[$i]} -eq 3 ]; then
			POP[$i]="+"
		fi
	done
}

########################################################################################
#	 main()
########################################################################################

declare -A DEAD
declare -A POP # key (C,R) value gen_num
init_population

trap bye_bye SIGINT SIGTERM INT EXIT
hello

GEN=1
NEIG_COUNT=0
while [ $MAX_GEN -le 0 ] || [ $MAX_GEN -gt $GEN ] ; do
	draw_dead
	draw_population
	draw_status

	#sleep 1
	case "`dd bs=1 count=1 iflag=nonblock status=none 2>/dev/null`" in
	#case "`dd bs=1 count=1 status=none 2>/dev/null`" in
	"") break
		;;
	esac

	draw_dead $_CLEAR$GREY
	for i in "${!DEAD[@]}"; do # DEAD= does not work, declare -A DEAD also
		unset DEAD[$i]
	done
	check_population

	GEN=$(( $GEN + 1 ))
done

