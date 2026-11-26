# noobmaisfier Arch & Multi-App Repository

Central package repository for compiled applications maintained by [noobmaisfier](https://github.com/noobmaisfier).

## Quick start (Arch Linux)

Add the repository once to `/etc/pacman.conf`:

```ini
[noobmaisfier]
SigLevel = Optional TrustAll
Server = https://github.com/noobmaisfier/repo/releases/download/$arch
```

Then install or update any hosted package with `pacman`:

```sh
sudo pacman -Syu swayfs
```

## Hosted Packages (`x86_64`)

| Package | Source | Description |
| --- | --- | --- |
| `swayfs` | [noobmaisfier/swayfs](https://github.com/noobmaisfier/swayfs) | SwayFX fork focused on low RAM/CPU usage |
| `kumi` | [noobmaisfier/A28](https://github.com/noobmaisfier/A28) | Wayland desktop shell (`kumi`, `kumi-lockscreen`, `kumizo`) |

## Publishing packages

### 1. From any public GitHub repository (GitHub Actions)

Run the [`publish-pkg.yml`](.github/workflows/publish-pkg.yml) workflow either from the **Actions** tab or with `gh`:

```sh
# Build from a repo PKGBUILD and add to [noobmaisfier]
gh workflow run publish-pkg.yml -R noobmaisfier/repo \
  -f source_repo=noobmaisfier/swayfs \
  -f ref=v0.6.swayfs.5 \
  -f pkgbuild_dir=packaging/aur/swayfs

# Or import a prebuilt .pkg.tar.zst release asset URL
gh workflow run publish-pkg.yml -R noobmaisfier/repo \
  -f pkg_url=https://github.com/noobmaisfier/swayfs/releases/download/v0.6.swayfs.5/swayfs-0.6.swayfs.5-1-x86_64.pkg.tar.zst
```

### 2. From a local build (private repos or quick uploads)

Requires `pacman` (`repo-add`), `bsdtar`, and `gh` authenticated as `noobmaisfier`:

```sh
./scripts/publish-pkg.sh /path/to/app-1.0-1-x86_64.pkg.tar.zst
```
