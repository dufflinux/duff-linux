Hello
Thank you for trying d77void.

To run the tui installer just open a terminal and type:

```
sudo d77void-installer
```

Note: 

To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.

Alternatively you can use Calamares to install the system; to use it just open the menu and type calamares.

## Keybinds

super + return -> terminal

super + shift + x -> logout

super + shift + q -> close window

super + a -> rofi

super + x -> powermenu

super + b -> web browser

super + f -> pcmanfm

super + l -> slock

super + m -> geary

super + o -> run

super + p -> scrot

super + s -> scratchpad

## Tweaks

My new d77 theme now uses eww (Elkowar Wacky Widgets) as system bar.
This theme was designed to work out of the box in 1920x1080 resolution. If your screen doesn't have this resolution 
you should adapt the theme eww.css to your resolution. The best way to do it is increasing/decreasing the .title space.
This eww bar assumes BAT0, so if your laptop has BAT1 you have to change it on eww.yuck.

Have fun!
