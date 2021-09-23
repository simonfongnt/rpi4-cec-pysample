import cec
import subprocess

def getKey(message):
    if   "SetCurrentButton" in message:
        return message.split('(')[0][17:-1], None, None
    elif "key released" in message:
        return None, None, message.split('(')[0][14:-1]
    elif "01:8a:91" in message:
        return None, None, 'return'
    return None, None, None

def cecCb(event, level, time, message):
    pKey, hKey, rKey = getKey(message)
    if pKey or hKey or rKey:
        print(pKey, hKey, rKey)
    else:
        print(message)
    cmds = []
    # High Priority    
    if      pKey == 'channel up':
        cmds = ['/usr/bin/amixer set Master 1%+',]
    elif    pKey == 'channel down':
        cmds = ['/usr/bin/amixer set Master 1%-',]
    elif    pKey == 'up':
        cmds = ['/usr/bin/amixer set Master 1%+',]
    elif    pKey == 'down':
        cmds = ['/usr/bin/amixer set Master 1%-',]
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
    # run commands
    for cmd in cmds:
        subprocess.call(
            cmd,
            shell=True, 
            )








cec.add_callback(cecCb, cec.EVENT_LOG)
cec.init()
while True: pass