#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/paths.sh"
assistant_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hermes-assistant"
assistant_unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
assistant_unit_file="$assistant_unit_dir/hermes-assistant.service"
assistant_image="docker.io/nousresearch/hermes-agent:latest"

if ! command -v podman >/dev/null 2>&1; then
  echo "Podman is not installed. Run: $project_dir/scripts/install-prerequisites.sh" >&2
  exit 1
fi

echo "Projects folder mounted into the container: $approved_projects_root"
echo "Hermes working directory: $assistant_project_dir"

umask 077
mkdir -p "$assistant_data_dir" "$assistant_data_dir/exports" "$assistant_data_dir/codex" "$assistant_data_dir/locks" "$assistant_unit_dir"
chmod 700 "$assistant_data_dir" "$assistant_data_dir/exports" "$assistant_data_dir/codex" "$assistant_data_dir/locks"

config_template="$(<"$project_dir/config/hermes-config.yaml")"
if [[ ! -e "$assistant_data_dir/config.yaml" ]]; then
  printf '%s\n' "${config_template//@REPO_FOLDER@/$(basename "$project_dir")}" > "$assistant_data_dir/config.yaml"
  chmod 600 "$assistant_data_dir/config.yaml"
else
  # Older installs used fixed working directories. Point them at this clone.
  temporary_config="$(mktemp "$assistant_data_dir/config.yaml.new.XXXXXX")"
  trap 'rm -f "$temporary_config"' EXIT
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      "  cwd: /workspace/personal-assistant" | "  cwd: /workspace/projects/personal assesteant")
        line="  cwd: $assistant_project_dir" ;;
    esac
    printf '%s\n' "$line"
  done < "$assistant_data_dir/config.yaml" > "$temporary_config"
  if cmp -s "$temporary_config" "$assistant_data_dir/config.yaml"; then
    echo "Keeping existing $assistant_data_dir/config.yaml"
  else
    chmod 600 "$temporary_config"
    mv -f "$temporary_config" "$assistant_data_dir/config.yaml"
    echo "Updated the Hermes terminal working directory to $assistant_project_dir."
  fi
  rm -f "$temporary_config"
  trap - EXIT
fi

if [[ ! -e "$assistant_data_dir/.env" ]]; then
  install -m 600 "$project_dir/config/runtime.env" "$assistant_data_dir/.env"
else
  chmod 600 "$assistant_data_dir/.env"
  echo "Keeping existing $assistant_data_dir/.env"
fi

unit_template="$(<"$project_dir/systemd/hermes-assistant.service")"
# systemd treats % as a specifier prefix, so escape it in the path.
printf '%s\n' "${unit_template//@PROJECT_DIR@/${project_dir//%/%%}}" > "$assistant_unit_file"
chmod 600 "$assistant_unit_file"
chmod 755 "$project_dir/scripts/"*.sh

podman pull "$assistant_image"
systemctl --user daemon-reload
systemctl --user enable hermes-assistant.service

echo "Bootstrap complete; the service is enabled but intentionally not started."
echo "Next run: $project_dir/scripts/secure-telegram-setup.sh"
