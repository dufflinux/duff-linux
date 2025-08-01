# d77void iso generator

To use the repo properly, clone the void-packages repo:

```
git clone https://github.com/void-linux/void-packages
```
copy /srcpkgs contents to void-packages repo and build the pkgs needed (at least Calamares). 

example
```
./xbps-src binary-bootstrap

./xbps-src pkg calamares
```

terminal example)

```
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs/ -b fluxbox -- -T d77void
```

## side note *hyprland*

To use it properly, run this:

```
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs/ -r https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc -b hyprland -- -T d77void
```

instead of the usual mkiso.sh command; it is needed to accept a new outside repo.

## side note *cosmic*

To use it properly, run this:

```
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs/ -r https://bellawagner.de/repo/x86_64 -b cosmic -- -T d77void
```

instead of the usual mkiso.sh command; it is needed to accept a new outside repo.

## side note *labwc*

To use it properly, compile labwc-menu-generator and labwc-tweaks-qt using void-packages and run this:

```
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs -b labwc -- -T d77void -v linux6.11
```

instead of the usual mkiso.sh command; it is needed to accept a local repo or to remove labwc-menu-generator, labwc-tweaks-qt and sfwbar packages from the d77 labwc variant.

Happy hacking. 
