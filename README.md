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

> [!TIP]
> Still curious and/or need help? Check the repository's wiki (https://github.com/duffnshmrt/duff-linux/wiki) and if that fails, feel free to raise an issue (https://github.com/duffnshmrt/duff-linux/issues) for anything else related to the project.

## ISO Build Helpers

This repo now includes helper scripts under `scripts/` to bootstrap `void-packages`
and launch common ISO builds without having to retype the full commands.

Setup everything for ISO generation:

```bash
./scripts/setup-iso-build-env.sh
```

That script:
- uses the current `duff-linux` checkout
- clones `void-packages` alongside it if needed
- runs `./xbps-src binary-bootstrap`
- syncs `build/srcpkgs/` into `void-packages/srcpkgs/`
- enables `XBPS_ALLOW_RESTRICTED=yes`
- builds `calamares`, `dkms`, and `nvidia`

Build the common ISO variants:

```bash
./scripts/build-amd-6.19.sh
./scripts/build-amd-7.0.sh
./scripts/build-nvidia-6.19.sh
./scripts/build-nvidia-7.0.sh
```

All four wrappers call `sudo ./d77 ...` with the correct repo and kernel arguments.
If your `void-packages` checkout lives somewhere else, set `VOID_PACKAGES_DIR=/path/to/void-packages`
before running the scripts.

---
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/H2H7V02MM) ![Total Downloads](https://img.shields.io/sourceforge/dt/duff-linux?label=Total%20Downloads&style=for-the-badge)
![Monthly Downloads](https://img.shields.io/sourceforge/dm/duff-linux?label=Monthly%20Downloads&style=for-the-badge)
