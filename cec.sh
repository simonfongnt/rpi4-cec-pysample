#!/bin/bash
ctimeout=60000  # mS, startup timeout, exceeding to reset service
lastts=$(date +%s%N) # timestamp of last loop
thists=$lastts  # timestamp of this loop
lasttdelta=$ctimeout # timestamp delta of last loop
thistdelta=$ctimeout # timestamp delta of this loop

mispd=10  # initial mouse pixel
miacc=10   # initial mouse acceleration

limitofretry=2  # limit of retry, exceeding to reset service
numofretry=0  # counter for retry

mode="mouse"  # arrow mode (mouse/keypad) changed by "electronic program guide"
presskey=""  # pressed key

lasttype=""  # lasttype for repeating input (movex/movey/press/scroll)
pvar=0   # key variable for repeating input
macc=0   # acceleration for mouse motion

while :
do
    # read line from service std and save to $oneline with 1s timeout
    if read -t 1 oneline; then
 #echo $oneline
 # holding key
 # key pressed: right (4) current(ff) duration(0) - OK
 # key pressed: right (4, 0) - NO
 if   [ "$lasttype" == "movex" ]  &&  [[ "$oneline" == *" current"* ]]; then
     xdotool mousemove_relative -- $pvar 0 # mouse left/right
     pvar=$((pvar + macc))   # x-acceleration
 elif [ "$lasttype" == "movey" ]  &&  [[ "$oneline" == *" current"* ]]; then
     xdotool mousemove_relative -- 0 $pvar # mouse up/down
     pvar=$((pvar + macc))   # y-acceleration
 elif [ "$lasttype" == "press" ]  && [[ "$oneline" == *" current"* ]]; then
     xdotool key $pvar     # key pressed
 elif [ "$lasttype" == "scroll" ]  && [[ "$oneline" == *" current"* ]]; then
     xdotool click $pvar    # mouse scroll up/down
 elif [[ "$oneline" == *"key released: "* ]]; then
     echo $oneline

     lasttdelta=0   # connected
     lasttype=""
     pvar=0
     macc=0

 # Restart Conditions - no last type and Recorder in line
 elif [ -z "$lasttype" ] ; then
     echo $oneline

     # no holding key already
     if [[ "$oneline" == *" current"* ]]; then
     
  presskey=$(grep -oP '(?<=sed: ).*?(?= \()' <<< $oneline)
  # last key is empty and pressed a key
  if [ -n "$presskey" ]; then

      lasttdelta=0   # connected
      
      # normal press
      case "$presskey" in
   "1")
       xdotool key "Ctrl+F4"  #Chrome-Close Tab
       ;;
   "2")
       xdotool key "Ctrl+Tab"  #Chrome-Next Tab
       ;;
   "3")
       xdotool key "Home"  #mouse-scroll to top
       ;;
   "4")
       xdotool key "Alt_L+F4"  #OS-Close Window      
       ;;
   "5")
       xdotool key "Alt_L+Tab"  #OS-Next Window
       ;;
   "6")
       xdotool key "Ctrl+Alt+Up" #OS-Maximize Window
       ;;
   "7")
       pkill chromium &  #OS-kill Chrome
       pkill pcmanfm &  #OS-kill explorer
       pkill vlc &   #OS-kill player
       ;;
   "8")
       ;;
   "9")
       xdotool key "End"  #mouse-scroll to bottom
       ;;
   "0")
       xdotool key "Ctrl+f"  #Player-Open Browser
       ;;
   "previous channel")
       xdotool key "Ctrl+Shift+t"  #Chrome-Previous Opened Tabs
       ;;
   ".")    
       sudo service lightdm restart %F #OS-Reset Desktop
       ;;
   "channel up")
       lasttype="scroll"
       pvar=4    #mouse scroll up
       xdotool click $pvar
       ;;
   "channel down")
       lasttype="scroll"
       pvar=5    #mouse scroll down
       xdotool click $pvar
       ;;
   "up")
    amixer -D pulse sset Master 5%+
    #    if [[ "$mode" == "keypad" ]]; then
    # lasttype="press"
    # pvar="Up"
    # xdotool key $pvar
    #    else
    # lasttype="movey"
    # pvar=$((-1 * mispd))
    # xdotool mousemove_relative -- 0 $pvar #move mouse up
    # macc=$((-1 * miacc))
    #    fi
       ;;
   "down")
    amixer -D pulse sset Master 5%-
    #    if [[ "$mode" == "keypad" ]]; then
    # lasttype="press"
    # pvar="Down"
    # xdotool key $pvar
    #    else
    # lasttype="movey"
    # pvar=$(( 1 * mispd))
    # xdotool mousemove_relative -- 0 $pvar #move mouse down
    # macc=$(( 1 * miacc))
    #    fi
       ;;
   "left")
       if [[ "$mode" == "keypad" ]]; then
    lasttype="press"
    pvar="Left"
    xdotool key $pvar
       else
    lasttype="movex"
    pvar=$((-1 * mispd))
    xdotool mousemove_relative -- $pvar 0 #move mouse left
    macc=$((-1 * miacc))
       fi
       ;;
   "right")
       if [[ "$mode" == "keypad" ]]; then
    lasttype="press"
    pvar="Right"
    xdotool key $pvar
       else
    lasttype="movex"
    pvar=$(( 1 * mispd))
    xdotool mousemove_relative -- $pvar 0 #move mouse right
    macc=$(( 1 * miacc))
       fi
       ;;
   "select")
       if [[ "$mode" == "keypad" ]]; then
    xdotool key Return
       else
    xdotool click 1 #left mouse button click
       fi
       ;;
   "return") # unuseable
       #xdotool key "Alt_L+Left" #WWW-Back
       #xdotool click 2 #Right mouse button click
       #xdotool key home #
       ;;
   "exit")
       #echo Key Pressed: EXIT
       xdotool key BackSpace
       ;;
   "electronic program guide")
       echo MODE: GUIDE
       #xdotool key "Ctrl+1"   #WWW-Back
       #xdotool key "Home"    #WWW-Back
       if [[ "$mode" == "mouse" ]]; then
    mode="keypad"
    xdotool mousemove_relative -- -10000 0  #move mouse most left
    xdotool mousemove_relative -- 0 10000  #move mouse most down
       else
    mode="mouse"
    xdotool mousemove_relative -- -10000 0  #move mouse most left
    xdotool mousemove_relative -- 0 10000  #move mouse most down
    
    for i in {1..12}
    do
        xdotool mousemove_relative -- 48 0  #move mouse right
        xdotool mousemove_relative -- 0 -32  #move mouse up
    done
    
       fi
       ;;
   "F2")
       #echo Key Pressed: RED C
       xdotool key "Shift+Tab"  #WWW-last-clickable item
       ;;
   "F3")
       #echo Key Pressed: GREEN C
       xdotool key "Ctrl+v" #WWW-Back
       ;;
   "F4")
       #echo Key Pressed: YELLOW C
       xdotool key Return
       ;;
   "F1")
       #echo Key Pressed: BLUE C
       xdotool key Tab   #WWW-next-clickable item
       ;;
   "rewind")
       #echo Key Pressed: REWIND
       xdotool key "Alt_L+Left"  #WWW-previous-page
       xdotool key "p"
       ;;
   "pause")
       #echo Key Pressed: PAUSE
       xdotool key "F5"   #WWW-refresh-page
       ;;
   "Fast forward")
       #echo Key Pressed: FAST FORWARD
       xdotool key "Alt_L+Right"  #WWW-next-page
       xdotool key "n"
       ;;
   "record")
       #xdotool key space
       xdotool click --repeat 2 --delay 100 1 #left mouse button click
       ;;
   "play")
       #echo Key Pressed: PLAY
       xdotool key space
       ;;
   "stop")
       ## with my remote I only got "STOP" as key released (auto-released), not as key pressed; see below
       #echo Key Pressed: STOP
       xdotool key Escape #
       ;;
   *)
       0 #echo Unrecognized Key Pressed: "$presskey" : "$oneline"
       ;;
      esac
  fi
     # Restart Conditions - various issues
     # Recorder 1 (1) ...
     elif [[ "$oneline" == *" Recorder "* ]]; then

  # handshake count
  if [[ $recorderline == *"active source"* ]]; then
      lasttdelta=0   # connected
      numofretry=$((numofretry+1))
      echo Number of Retry $numofretry
      # Reset: Connection Retry Failure
      # TV (0): device status changed into ...
      if [ $numofretry -ge $limitofretry ]; then
   echo Kill cec-client due to various issues
   pkill cec-client
   pkill cec.sh
   break
      fi
  
  # connected
  elif [[ $recorderline == *"activated"* ]]; then # activated/deactivated
      lasttdelta=0   # connected
      numofretry=0
      echo Number of Retry $numofretry
      
  fi
     
     # TV (0)...
     elif [[ "$oneline" == *" TV \("* ]]; then
     
  # Reset connection variable for new check
  # TV (0) -> Broadcast (F): routing change (80)
  # TV (0): power status changed from 'unknown' to 'on'
  if [[ "$oneline" == *" routing change "* ]] || [[ "$oneline" == *" status changed "* ]]; then
      lastts=$(date +%s%N)
      thists=$lastts
      thistdelta=$ctimeout
      lasttdelta=$ctimeout
      numofretry=0
  fi
     
     fi

 fi
    
    # read line timeout
    # Restart Conditions - timeout
    else
        # timeout check is valid
        if [ "$lasttdelta" -ne "0" ]; then
            # update
            thists=$(date +%s%N)
            thistdelta=$((($thists - $lastts) / 1000000))
            lasttdelta=$thistdelta
        fi

        # timeout?
        if   [ "$thistdelta" -gt "$ctimeout" ]; then
            echo Kill cec-client due to timeout $ctimeout
            pkill cec-client
            pkill cec.sh
            break
        fi
    
    fi

done
