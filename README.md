# Duff-Linux 🍺

[![Download Duff Linux](https://a.fsdn.com/con/app/sf-download-button)](https://sourceforge.net/projects/duff-linux/files/latest/download)

> [!NOTE]
> This project would not be possible without the use of d77void. Please go check it out here: https://github.com/dani-77/d77void

An opinionated distro based off dani-77's d77void Linux distribution, with the following notable features:
- KDE Plasma as the desktop environment, uses latest version available
- Linux kernel 7.0.0_1 instead of the default older version
- Live environment with Calamares installer
- BTRFS with automatic snapshots (both pre-transaction and regular system backups)
- OctoXBPS as a graphical application to manage native packages
- OctoXBPS Notifier to tell you when updates are available
- Flatpak support with Discover out of the box
- Lightly themed
- Uses faster and more modern ZRAM for swap
- Void Linux under the hood

<img src="https://github.com/duffnshmrt/duff-linux/blob/main/duff-linux.png?raw=true" width="300">

# ISO Generation Guide

1. The first step is to clone this repo, Void's official packages repo, and then finally to build binary-bootstrap. This sets up the "masterdir," which is like a mini-Void system inside a folder where your building happens.

```
git clone https://github.com/duffnshmrt/duff-linux
git clone https://github.com/void-linux/void-packages
cd void-packages
./xbps-src binary-bootstrap
```

2. Step two is to add d77's "secret sauce". Go to this repo's folder and copy everything inside its /build/srcpkgs folder into the /srcpkgs folder of the void-packages repo you just cloned. This gives Void the "recipes" for things like Calamares (the installer) that might not be in the official repos. Once done, you can build Calamares.
```
./xbps-src pkg calamares
```

3. Assuming everything went well, step three is to create the ISO 🎉. In a terminal in this directory/repository, run the following command:

```
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs/ -b plasma --
```
