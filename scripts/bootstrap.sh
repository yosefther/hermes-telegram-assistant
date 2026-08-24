#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assistant_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hermes-assistant"
assistant_unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
assistant_unit_file="$assistant_unit_dir/hermes-assistant.service"
assistant_image="docker.io/nousresearch/hermes-agent:latest"

if ! command -v podman >/dev/null 2>&1; then
  echo "Podman is not installed. Run: $project_dir/scripts/install-prerequisites.sh" >&2
  exit 1
fi

if [[ "$project_dir" != "/home/user/Projects/personal assesteant" ]]; then
  echo "Refusing unexpected project location: $project_dir" >&2
  exit 1
fi

umask 077
mkdir -p "$assistant_data_dir" "$assistant_data_dir/exports" "$assistant_data_dir/codex" "$assistant_data_dir/locks" "$assistant_unit_dir"
chmod 700 "$assistant_data_dir" "$assistant_data_dir/exports" "$assistant_data_dir/codex" "$assistant_data_dir/locks"

if [[ ! -e "$assistant_data_dir/config.yaml" ]]; then
  install -m 600 "$project_dir/config/hermes-config.yaml" "$assistant_data_dir/config.yaml"
else
  if grep -q '^  cwd: /workspace/personal-assistant$' "$assistant_data_dir/config.yaml"; then
    temporary_config="$(mktemp "$assistant_data_dir/config.yaml.new.XXXXXX")"
    trap 'rm -f "$temporary_config"' EXIT
    sed 's|^  cwd: /workspace/personal-assistant$|  cwd: /workspace/projects/personal assesteant|' \
      "$assistant_data_dir/config.yaml" > "$temporary_config"
    chmod 600 "$temporary_config"
    mv -f "$temporary_config" "$assistant_data_dir/config.yaml"
    trap - EXIT
    echo "Updated the Hermes terminal working directory to the approved projects tree."
  else
    echo "Keeping existing $assistant_data_dir/config.yaml"
  fi
fi

if [[ ! -e "$assistant_data_dir/.env" ]]; then
  install -m 600 "$project_dir/config/runtime.env" "$assistant_data_dir/.env"
else
  chmod 600 "$assistant_data_dir/.env"
  echo "Keeping existing $assistant_data_dir/.env"
fi

install -m 600 "$project_dir/systemd/hermes-assistant.service" "$assistant_unit_file"
chmod 755 "$project_dir/scripts/"*.sh

podman pull "$assistant_image"
systemctl --user daemon-reload
systemctl --user enable hermes-assistant.service

echo "Bootstrap complete; the service is enabled but intentionally not started."
echo "Next run: $project_dir/scripts/secure-telegram-setup.sh"
