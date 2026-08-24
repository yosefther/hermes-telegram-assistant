#!/usr/bin/env bash
set -euo pipefail

assistant_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hermes-assistant"
approved_projects_root="/home/user/Projects"
assistant_project_dir="/workspace/projects/personal assesteant"
assistant_export_dir="$assistant_data_dir/exports"
assistant_image="docker.io/nousresearch/hermes-agent:latest"
runtime_env_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/runtime.env"

test -d "$assistant_data_dir"
test -d "$approved_projects_root"
test -f "$assistant_data_dir/.env"
test -f "$assistant_data_dir/config.yaml"
test -f "$runtime_env_file"

exec podman run --rm \
  --name hermes-assistant \
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
  --stop-timeout=30 \
  --log-driver=journald \
  --env HERMES_HOME=/opt/data \
  --env HOME=/opt/data \
  --env CODEX_HOME=/opt/data/codex \
  --env PATH=/opt/data/codex-cli/node_modules/.bin:/opt/hermes/bin:/opt/hermes/.venv/bin:/opt/data/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  --env HERMES_UID=10000 \
  --env HERMES_GID=10000 \
  --env-file "$runtime_env_file" \
  --env-file "$assistant_data_dir/.env" \
  --volume "$assistant_data_dir:/opt/data:rw" \
  --volume "$approved_projects_root:/workspace/projects:rw" \
  --volume "$assistant_export_dir:/output:rw" \
  --workdir "$assistant_project_dir" \
  "$assistant_image" gateway run
