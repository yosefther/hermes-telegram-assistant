#!/usr/bin/env bash
set -euo pipefail

assistant_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hermes-assistant"
assistant_env_file="$assistant_data_dir/.env"

test -f "$assistant_env_file"
umask 077

read -r -s -p "Telegram bot token (hidden): " telegram_bot_token
printf '\n'
if [[ -z "$telegram_bot_token" ]]; then
  echo "No token entered; nothing changed." >&2
  exit 1
fi

echo "Send a message such as /start to your Telegram bot now. Waiting up to 90 seconds..."
telegram_identity="$({ TELEGRAM_SETUP_TOKEN="$telegram_bot_token" python3 - <<'PY'
import json
import os
import time
import urllib.error
import urllib.request

token = os.environ["TELEGRAM_SETUP_TOKEN"]
base = f"https://api.telegram.org/bot{token}"

def call(method, timeout=20):
    req = urllib.request.Request(f"{base}/{method}", headers={"User-Agent": "hermes-secure-setup/1"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        payload = json.load(response)
    if not payload.get("ok"):
        raise RuntimeError(payload.get("description", "Telegram API error"))
    return payload["result"]

call("getMe")
deadline = time.monotonic() + 90
offset = None
while time.monotonic() < deadline:
    method = "getUpdates?timeout=10&allowed_updates=%5B%22message%22%5D"
    if offset is not None:
        method += f"&offset={offset}"
    for update in call(method, timeout=15):
        offset = update["update_id"] + 1
        message = update.get("message") or {}
        sender = message.get("from") or {}
        user_id = sender.get("id")
        if user_id:
            username = sender.get("username") or "(no username)"
            print(f"{user_id}|{username}")
            raise SystemExit(0)
raise SystemExit("No Telegram message received before timeout")
PY
} 2>/dev/null)" || {
  unset telegram_bot_token
  echo "Telegram verification failed. Check the token and whether this bot has an existing webhook." >&2
  exit 1
}

telegram_user_id="${telegram_identity%%|*}"
telegram_username="${telegram_identity#*|}"
echo "Discovered Telegram account: $telegram_username (numeric ID $telegram_user_id)"
read -r -p "Authorize only this Telegram account? Type yes: " confirmation
if [[ "$confirmation" != "yes" ]]; then
  unset telegram_bot_token
  echo "Cancelled; nothing changed."
  exit 1
fi

temporary_env="$(mktemp "$assistant_data_dir/.env.new.XXXXXX")"
trap 'rm -f "$temporary_env"' EXIT

awk '!/^(TELEGRAM_BOT_TOKEN|TELEGRAM_ALLOWED_USERS|TELEGRAM_HOME_CHANNEL|TELEGRAM_ALLOW_ALL_USERS)=/' "$assistant_env_file" > "$temporary_env"
printf 'TELEGRAM_BOT_TOKEN=%s\n' "$telegram_bot_token" >> "$temporary_env"
printf 'TELEGRAM_ALLOWED_USERS=%s\n' "$telegram_user_id" >> "$temporary_env"
printf 'TELEGRAM_HOME_CHANNEL=%s\n' "$telegram_user_id" >> "$temporary_env"
printf '%s\n' 'TELEGRAM_ALLOW_ALL_USERS=false' >> "$temporary_env"
chmod 600 "$temporary_env"
mv -f "$temporary_env" "$assistant_env_file"
trap - EXIT
unset telegram_bot_token

echo "Telegram credentials saved with mode 600. The token was not printed."
echo "Next run: ./scripts/auth-codex.sh"
