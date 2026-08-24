#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "${XDG_DATA_HOME:-$HOME/.local/share}/hermes-assistant/codex-cli/node_modules/.bin/codex" ]]; then
  echo "Installing the official Codex CLI into the isolated Hermes data volume..."
  "$project_dir/scripts/container-command.sh" bash -lc 'npm install --prefix /opt/data/codex-cli @openai/codex && chmod -R go-rwx /opt/data/codex-cli /opt/data/codex'
else
  echo "The isolated Codex CLI is already installed."
fi

echo "Starting Hermes-managed OpenAI Codex OAuth. Follow the device-code instructions."
"$project_dir/scripts/container-command.sh" hermes auth add openai-codex

echo "Starting the separate Codex CLI OAuth required for delegated coding."
"$project_dir/scripts/container-command.sh" codex login --device-auth

echo "Checking both authentication stores without displaying credentials..."
"$project_dir/scripts/container-command.sh" hermes auth status openai-codex
"$project_dir/scripts/container-command.sh" codex login status
