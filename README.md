# Duff Linux 🍺

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

1. Clone this repo and Void's `void-packages` repo, then bootstrap `void-packages`. This creates the local build environment that produces the package repositories used by `d77`.

```
git clone https://github.com/duffnshmrt/duff-linux
git clone https://github.com/void-linux/void-packages
cd void-packages
./xbps-src binary-bootstrap
```

2. Copy the custom package templates from this repo into `void-packages/srcpkgs`, then build the local packages this project depends on. `calamares` provides the installer, and the local `dkms` override prevents NVIDIA ISO builds from pulling in the default Void kernel headers.
```
./xbps-src pkg calamares dkms
```

3. Build the ISO from this repo.

AMD / default ISO:

```
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs/ -b plasma --
```

NVIDIA ISO:

The proprietary `nvidia` package is a restricted package in Void and is built into a separate local `nonfree` repository. Enable restricted builds, build the package, then point `d77` at both your main and `nonfree` repos.

```
cd /home/$USER/void-packages
echo XBPS_ALLOW_RESTRICTED=yes >> etc/conf
./xbps-src pkg dkms
./xbps-src pkg nvidia

cd /home/$USER/duff-linux
sudo ./d77 -r /home/$USER/void-packages/hostdir/binpkgs/ -r /home/$USER/void-packages/hostdir/binpkgs/nonfree/ -g nvidia -b plasma --
```

`d77` defaults to the AMD profile, so `-g amd` is optional. If the local `nonfree` repo already exists, `d77` will now add it automatically for NVIDIA builds when you pass only `/hostdir/binpkgs/`.
