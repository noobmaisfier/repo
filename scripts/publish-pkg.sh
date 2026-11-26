#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-noobmaisfier/repo}"
TAG="${TAG:-x86_64}"
DB_NAME="${DB_NAME:-noobmaisfier}"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <pkg.tar.zst> [more-pkgs.tar.zst...]" >&2
  exit 1
fi

for cmd in gh repo-add bsdtar awk; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required tool: $cmd" >&2
    exit 1
  fi
done

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

stage="$workdir/stage"
mkdir -p "$stage"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release download "$TAG" --repo "$REPO" \
    --pattern "${DB_NAME}.db.tar.gz" \
    --pattern "${DB_NAME}.files.tar.gz" \
    --dir "$stage" || true
else
  gh release create "$TAG" --repo "$REPO" \
    --title "Arch Linux $TAG Repository" \
    --notes "Custom pacman repository for noobmaisfier packages ($TAG)."
fi

old_files=()
new_pkgs=()

for src in "$@"; do
  [ -f "$src" ] || { echo "File not found: $src" >&2; exit 1; }
  base="$(basename "$src")"
  case "$base" in
    *-debug-*.pkg.tar.zst)
      echo "Skipping debug package: $base" >&2
      continue
      ;;
    *.pkg.tar.*)
      ;;
    *)
      echo "Not a pacman package archive: $base" >&2
      exit 1
      ;;
  esac

  pkgname="$(bsdtar -xOf "$src" .PKGINFO | awk -F' = ' '$1=="pkgname"{print $2; exit}')"
  [ -n "$pkgname" ] || { echo "Failed to read pkgname from $src" >&2; exit 1; }

  if [ -f "$stage/${DB_NAME}.db.tar.gz" ]; then
    prev="$(bsdtar -tf "$stage/${DB_NAME}.db.tar.gz" | awk -F/ -v p="$pkgname" 'substr($1, 1, length(p)+1) == p"-" && substr($1, length(p)+2) ~ /^[^-]+-[^-]+$/ && $2=="desc"{print $0}' || true)"
    for entry in $prev; do
      old="$(bsdtar -xOf "$stage/${DB_NAME}.db.tar.gz" "$entry" | awk '/^%FILENAME%$/{getline; print; exit}')"
      if [ -n "$old" ] && [ "$old" != "$base" ]; then
        old_files+=("$old")
      fi
    done
  fi

  cp -f "$src" "$stage/$base"
  new_pkgs+=("$stage/$base")
done

[ "${#new_pkgs[@]}" -gt 0 ] || { echo "No packages to publish." >&2; exit 1; }

(
  cd "$stage"
  repo-add "${DB_NAME}.db.tar.gz" "${new_pkgs[@]##*/}"
  rm -f "${DB_NAME}.db" "${DB_NAME}.files"
  cp "${DB_NAME}.db.tar.gz" "${DB_NAME}.db"
  cp "${DB_NAME}.files.tar.gz" "${DB_NAME}.files"
)

upload_files=(
  "$stage/${DB_NAME}.db"
  "$stage/${DB_NAME}.db.tar.gz"
  "$stage/${DB_NAME}.files"
  "$stage/${DB_NAME}.files.tar.gz"
  "${new_pkgs[@]}"
)

gh release upload "$TAG" "${upload_files[@]}" --repo "$REPO" --clobber

for old in "${old_files[@]+"${old_files[@]}"}"; do
  gh release delete-asset "$TAG" "$old" --repo "$REPO" --yes || true
done

echo "Published to $REPO ($TAG): ${new_pkgs[*]##*/}"
