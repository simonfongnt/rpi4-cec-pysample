import time
import subprocess
import threading
from pynput import mouse
# global variable
cec     = None
flimit  = 5
fcount  = 0
volume  = None

connectLimit    = 12
connectts       = None
isConnect       = False

notifLongts   = 3000
notifShortts  = 90

# always monitor prompt input
def cecInput():
    while True:
        cecWrite(input())
# send notification to OS
def osNotify(
        t,
        msg,
        ):
    cmd = '/usr/bin/notify-send -t %s "%s"'%(
        str(t),
        msg,
        )
    subprocess.call(
        cmd,
        shell=True, 
        )
# monitor mouse action
def on_move(x, y):
    print('Pointer moved to {0}'.format(
        (x, y)))

def on_click(x, y, button, pressed):
    print('{0} at {1}'.format(
        'Pressed' if pressed else 'Released',
        (x, y)))
    if not pressed:
        # Stop listener
        return False
    else:
        cecWrite('as')

def on_scroll(x, y, dx, dy):
    print('Scrolled {0} at {1}'.format(
        'down' if dy < 0 else 'up',
        (x, y)))
# capture key from line
def getKey(line):
    if   "SetCurrentButton" in line:
        return line.split("SetCurrentButton ")[-1].split('(')[0][0:-1], None, None
    elif "key released" in line:
        return None, None, line.split("key released: ")[-1].split('(')[0][0:-1]
    elif "01:8a:91" in line:
        return None, None, 'return'
    return None, None, None
# get OS volume
def getVolume():    
    p = subprocess.Popen(
        '''amixer -c 1 -M -D pulse get Master | grep -o -E [[:digit:]]+%''',
        stdout=subprocess.PIPE,
        shell=True, 
        )
    out, err = p.communicate()
    vols = out.decode().split('%\n')
    return int(vols[0])
# continuously readline from CEC
def cecRead():
    global volume
    global isConnect
    global connectts
    volume = getVolume()
    while cec:
        line = cec.stdout.readline().decode()
        # until cec is killed
        if cec.poll() is not None:
            break
        if (
                'timeout' in line
            or  'unhandled' in line
            ):
            if 'Key' not in line:
                if (
                        not connectts
                    or  time.time() > connectts + connectLimit
                    ):
                    osNotify(notifLongts, 'CEC: Connecting')
                isConnect = False
                connectts = time.time()
            #     msg = line.split(']')[1][1:]
            #     osNotify(notifLongts, 'CEC: ' + msg)
            print(line[:-1])
            continue
        pKey, hKey, rKey = getKey(line)
        if (pKey or hKey or rKey):
            route(pKey, hKey, rKey)
        else:
            print(line[:-1])
            cecInits(line)
# send command to CEC
def cecWrite(cmd):
    global cec
    if cec:
        raw = cmd + '\n'
        raw = raw.encode()
        print('cecWrite:', raw)
        cec.stdin.write(raw)
        if cmd == 'r':
            cec.terminate() 
            cec.wait()
            # cec.kill()
            cec = None
# CEC initialization handlings
def cecInits(line):
    global flimit
    global fcount
    # global volume
    # volume = getVolume()
    if (    # switch to other channel
            "making " in line
        and " the active source" in line
        and " Recorder 1 (1)" not in line
            ):
        cecWrite('is')
        # cecWrite('r')
        osNotify(notifLongts, 'CEC: Inactive')
    # elif "making Recorder 1 (1) the active source" in line:
    #     cec.stdin.write('as' + '\n')
    elif "power status changed from 'on' to 'standby'" in line:
        cecWrite('r')
        osNotify(notifLongts, 'CEC: Reset')
    elif "failed to make 'Recorder 1' the active source. will retry later" in line:
        # cecWrite('r')
        fcount  = fcount + 1
        if fcount >= flimit:
            fcount  = 0
            cecWrite('r')
            osNotify(notifLongts, 'CEC: Reset')
        # else:
        #     cecWrite('as')
        #     osNotify(notifLongts, 'CEC: Active')

    # TV (0): device status changed into 'present'
    # Recorder 1 (1): device status changed into 'handled by libCEC'
# routing keys to action
def route(pKey, hKey, rKey):
    global volume
    cmds = []
    # High Priority    
    if      pKey == 'channel up':
        # cmds = ['/usr/bin/amixer set Master 1%+',]
        volume = volume + 1
        cmds = ['/usr/bin/pactl set-sink-volume 0 {:d}%'.format(volume),]
        osNotify(notifShortts, str(volume))
    elif    pKey == 'channel down':
        # cmds = ['/usr/bin/amixer set Master 1%-',]
        volume = volume - 1
        cmds = ['/usr/bin/pactl set-sink-volume 0 {:d}%'.format(volume),]
        osNotify(notifShortts, str(volume))
    elif    pKey == 'up':
        volume = volume + 1
        cmds = ['/usr/bin/pactl set-sink-volume 0 {:d}%'.format(volume),]
        osNotify(notifShortts, str(volume))
    elif    pKey == 'down':
        volume = volume - 1
        cmds = ['/usr/bin/pactl set-sink-volume 0 {:d}%'.format(volume),]
        osNotify(notifShortts, str(volume))
    elif    pKey == 'left':
        cmds = ['xdotool key "Alt_L+Left"',]
    elif    pKey == 'right':
        cmds = ['xdotool key "Alt_L+Right"',]
    # Low Priority
    elif    pKey == 'select':
        cmds = ['xdotool key BackSpace',]
    elif    pKey == 'exit':
        cmds = [
                'xdotool click 1',
                'xdotool key Return',
                ]
    elif    pKey == 'rewind':
        cmds = [
                'xdotool key Left',
                # 'xdotool key "j"',
                # 'xdotool key "p"',
                ]
    elif    pKey == 'Fast forward':
        cmds = [
                'xdotool key Right',
                # 'xdotool key "l"',
                # 'xdotool key "n"',
                ]
    elif    pKey == 'return':
        cmds = ['xdotool key "F5"',]
    elif    pKey == 'play':
        cmds = ['xdotool key "space"',]
    elif    pKey == 'stop':
        cmds = ['xdotool key Escape #',]
    elif    pKey == 'electronic program guide':
        cecWrite('r')
        osNotify(notifLongts, 'CEC: Reset')
    # run commands
    for cmd in cmds:
        subprocess.call(
            cmd,
            shell=True, 
            )
# main

# # Collect events until released
# with mouse.Listener(
#         # on_move=on_move,
#         on_click=on_click,
#         # on_scroll=on_scroll,
#         ) as listener:
#     listener.join()

# # ...or, in a non-blocking fashion:
# listener = mouse.Listener(
#     # on_move=on_move,
#     on_click=on_click,
#     # on_scroll=on_scroll,
#     )
# # listener.start()

ths = {}

ths['prompt']   = threading.Thread(target=cecInput)
ths['prompt'].daemon = True
ths['prompt'].start()
# ths['mouse']   = threading.Thread(target=listener.start)
# ths['mouse'].daemon = True
# ths['mouse'].start()
while True:
    # init
    if cec == None:
        if 'read' in ths:
            ths['read'].join()
        time.sleep(5)
        osNotify(notifLongts, 'CEC: Launching')
        cec = subprocess.Popen(
            "cec-client",
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            )
        ths['read']     = threading.Thread(target=cecRead)
        ths['read'].daemon = True
        ths['read'].start()
        cecWrite('log 16')  # DEBUG only
        # cecWrite('log 8')  # TRAFFIC only
    
    # connected?
    if (
            connectts
        and time.time() > connectts + connectLimit
            ):
        if not isConnect:
            osNotify(notifLongts, 'CEC: Connected')
        isConnect = True
