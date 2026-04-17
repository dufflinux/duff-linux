# Duff-Linux 🍺 (WIP)

> [!NOTE]
> This project would not be possible without the use of d77void. Please go check it out here: https://github.com/dani-77/d77void

A personal/heavily opinionated distro based off dani-77's d77void Linux distribution. Please note this is still heavily work-in-progress.

# ISO Generation Guide

1. The first step is to clone this repo, Void's official packages repo, and then finally to build binary-bootstrap. This sets up the "masterdir," which is like a mini-Void system inside a folder where your building happens.

```
git clone https://github.com/duffnshmrt/duff-linux
git clone https://github.com/void-linux/void-packages
cd void-packages
./xbps-src binary-bootstrap
```

2. Step two is to add d77's "secret sauce". Go to this repo's folder and copy everything inside its /srcpkgs folder into the /srcpkgs folder of the void-packages repo you just cloned. This gives Void the "recipes" for things like Calamares (the installer) that might not be in the official repos. Once done, you can build Calamares.
```
./xbps-src pkg calamares
```

3. Assuming everything went well, step three is to create the ISO 🎉. Using KDE as an example:

```
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs/ -b kde -- -T d77void
```
