# Simple Rpi4 CEC Python Sample

- sudo apt-get update
- sudo apt-get install cmake libudev-dev libxrandr-dev python-dev swig
- sudo apt-get install cec-utils xdotool
- pip3 install cec
- ~/Documents/scripts/irctl.py
- sudo nano /etc/xdg/autostart/display.desktop.
    [Desktop Entry]
    Name=irctl
    Exec=/usr/bin/python3 /home/pi/Documents/scripts/irctl.py
