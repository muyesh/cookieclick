#!/bin/bash
cnt=0
PX=-1
PY=-1

function get_x {
    xdotool getmouselocation --shell|grep 'X='|sed 's/X=//g'
}

function get_y {
    xdotool getmouselocation --shell|grep 'Y='|sed 's/Y=//g'
}

function get_stable_xy {
    waitsecs=$1
    keepcnt=0
    x=$(get_x)
    y=$(get_y)
    px=0
    py=0
    while :
    do
        x=$(get_x)
        y=$(get_y)
        echo -en "                               \r" >&2
        echo -en "x=${x} , y=${y} : " >&2
        if [ $px -eq $x ] && [ $py -eq $y ]
        then
            echo -en $(( $(( $waitsecs * 10 )) - $keepcnt )) >&2
            keepcnt=$(( $keepcnt + 1 ))
        else
            echo -en "Don't move!!" >&2
            keepcnt=0
        fi
        px=$x
        py=$y
        if [ $keepcnt -gt $(( $waitsecs * 10 )) ]
        then
            break
        fi
        sleep 0.1
    done
    echo -en "                               \n" >&2
    echo $x" "$y
}

# get area start point
echo "Move to 'Start Point' and keep same position to 2 secs: "
result_start=$(get_stable_xy 2)
start_x=$(echo $result_start|cut -d' ' -f1)
start_y=$(echo $result_start|cut -d' ' -f2)
# wait 1.5 sec
sleep 1.5
# get area end point
echo "Move to 'End Point' and keep same position to 2 secs: "
result_end=$(get_stable_xy 2)
end_x=$(echo $result_end|cut -d' ' -f1)
end_y=$(echo $result_end|cut -d' ' -f2)

# get area end point
total_clicks=0
current_clicks=0
while :
do
    sleep 0.5
    start_clicks=$total_clicks
    if [ $cnt -gt 2 ]
    then
        pre_x=$(get_x)
        ms=1000
        start_ms=$(date +%s%3N)
        while :
        do
            x=$(get_x)
            if [ $x -ne $pre_x ]
            then
                break;
            else
                for no in {1..10}
                do
                    xdotool click 1 >/dev/null 2>&1
                    total_clicks=$(( $total_clicks + 1 ))
                    current_clicks=$(( $total_clicks - $start_clicks ))
                    echo -en "                                                                                           \r"
                    echo -en "Speed $(( $current_clicks * 1000 / $ms )) cps : ${current_clicks} / ${total_clicks} clicks\r"
                done
                end_ms=$(date +%s%3N)
                ms=$(( $end_ms - $start_ms ))
            fi
            pre_x=$x
        done
    fi
    X=$(get_x)
    Y=$(get_y)
    # check area
    echo -en "                                                                                         \r"
    if [ $X -gt $start_x ] && [ $X -lt $end_x ] && [ $Y -gt $start_y ] && [ $Y -lt $end_y ]
    then
        # check stable
        if [ $PX -eq $X ] && [ $PY -eq $Y ]
        then
            cnt=$(( $cnt + 1 ))
            echo -en "Inside of a target area\r"
        else
            cnt=0
            echo -en "Don't move!\r"
        fi
    else
        cnt=0
        echo -en "Outside of a target area: clicks[ current=${current_clicks} / total=${total_clicks} ]\r"
    fi
    PX=$X
    PY=$Y
done

