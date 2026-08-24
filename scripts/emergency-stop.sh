#!/usr/bin/env bash
set -euo pipefail

systemctl --user stop hermes-assistant.service || true
podman stop --time 5 hermes-assistant 2>/dev/null || true
echo "Hermes gateway stopped."
