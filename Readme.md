# Simple Rpi4 CEC Python Sample

- sudo apt-get update
- sudo apt-get install cmake libudev-dev libxrandr-dev python-dev swig
- sudo apt-get install cec-utils xdotool
- sudo apt-get install xfce4-notifyd
  or
  sudo apt-get install notify-osd
- pip3 install cec pynput
- ~/Documents/scripts/irctl.py
- sudo nano /etc/xdg/autostart/irctl.desktop
    [Desktop Entry]
    Name=irctl
    Exec=/usr/bin/python3 /home/pi/Documents/scripts/rpi4-cec-pysample/irctl.py

    Exec=/bin/sh -c 'exec /usr/bin/python3 /home/pi/Documents/scripts/rpi4-cec-pysample/irctl.py >> /home/pi/Documents/scripts/rpi4-cec-pysample/logs.log 2>&1'