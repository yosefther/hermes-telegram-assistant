#!/usr/bin/env bash
set -euo pipefail

assistant_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hermes-assistant"
approved_projects_root="/home/user/Projects"
assistant_project_dir="/workspace/projects/personal assesteant"
assistant_export_dir="$assistant_data_dir/exports"
assistant_image="docker.io/nousresearch/hermes-agent:latest"

if (($# == 0)); then
  echo "Usage: $0 <hermes-or-shell-command> [args...]" >&2
  exit 2
fi

podman_tty_args=(--interactive)
if [[ -t 0 && -t 1 ]]; then
  podman_tty_args+=(--tty)
fi

exec podman run --rm "${podman_tty_args[@]}" \
  --userns=keep-id:uid=10000,gid=10000 \
  --user=0 \
  --cap-drop=ALL \
  --cap-add=DAC_OVERRIDE \
  --cap-add=CHOWN \
  --cap-add=FOWNER \
  --cap-add=SETUID \
  --cap-add=SETGID \
  --security-opt=no-new-privileges \
  --pids-limit=256 \
  --cpus=1 \
  --memory=5g \
  --env HERMES_HOME=/opt/data \
  --env HOME=/opt/data \
  --env CODEX_HOME=/opt/data/codex \
  --env PATH=/opt/data/codex-cli/node_modules/.bin:/opt/hermes/bin:/opt/hermes/.venv/bin:/opt/data/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  --env HERMES_UID=10000 \
  --env HERMES_GID=10000 \
  --env-file "$assistant_data_dir/.env" \
  --volume "$assistant_data_dir:/opt/data:rw" \
  --volume "$approved_projects_root:/workspace/projects:rw" \
  --volume "$assistant_export_dir:/output:rw" \
  --workdir "$assistant_project_dir" \
  "$assistant_image" "$@"
