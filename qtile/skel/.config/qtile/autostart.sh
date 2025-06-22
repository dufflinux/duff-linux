#!/usr/bin/env bash
export QT_QPA_PLATFORM=wayland
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark" &
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' &
dunst &
udiskie -a &
xcompmgr -c -f -n &
xautolock -time 5 -locker slock &
redshift -l 41.6:-8.62 -t 5700:3500 -b 0.8 &
synclient TapButton1=1 &
synclient TapButton2=3 &
synclient TapButton3=2 &
