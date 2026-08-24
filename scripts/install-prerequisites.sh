#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required for this one system-package installation step." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y podman podman-compose uidmap slirp4netns fuse-overlayfs passt ffmpeg
sudo loginctl enable-linger "$(id -un)"

echo "Prerequisites installed. Next run: ./scripts/bootstrap.sh"
