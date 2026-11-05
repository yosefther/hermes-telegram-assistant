# hermes-telegram-assistant

My setup for running [Hermes Agent](https://hermes-agent.nousresearch.com/) as a personal assistant I talk to over Telegram. It runs the official Hermes image in rootless Podman and can work on files in my projects folder, but nothing else in my home directory.

## How to run it

You need Ubuntu/Debian (the install script uses `apt-get`), a Telegram bot token and an OpenAI account for Codex OAuth.

```bash
./scripts/install-prerequisites.sh   # podman, uidmap, ffmpeg etc. Asks for sudo once
./scripts/bootstrap.sh               # data dir, config, pulls the image, enables the user service
./scripts/secure-telegram-setup.sh   # hidden token prompt, then locks the bot to your Telegram ID
./scripts/auth-codex.sh              # device-code OAuth for Hermes and the Codex CLI
```

Check it in the foreground first, then start the gateway:

```bash
./scripts/container-command.sh hermes doctor
./scripts/container-command.sh hermes
systemctl --user start hermes-assistant.service
```

Day to day:

```bash
systemctl --user status hermes-assistant.service
journalctl --user -u hermes-assistant.service -f
./scripts/emergency-stop.sh
```

Updating is manual: `podman pull docker.io/nousresearch/hermes-agent:latest`, then restart the service. Back up `~/.local/share/hermes-assistant` with the service stopped. That folder has credentials in it, so encrypt the backup.

If Podman complains about UID maps, check that `uidmap` is installed and that `/etc/subuid` and `/etc/subgid` have a range for your user.

## How it works

There's no application code here, only config and shell scripts around the upstream image.

- `scripts/run-container.sh` is what the systemd unit runs. It starts `hermes gateway run` in Podman with the mounts and limits below.
- `scripts/container-command.sh` runs one-off commands (`hermes doctor`, `codex login status`) in the same container setup.
- `config/hermes-config.yaml` sets the model (OpenAI Codex), the toolsets per platform, memory, and limits on turns, tool calls and tool-failure loops.
- `AGENTS.md` holds the rules the agent and any delegated Codex session follow: what it can do freely, and what needs my explicit approval each time (sending messages, commits, pushes, deploys, destructive commands).

## Security

The container is the real boundary. Prompt rules and approval prompts are extra layers on top. More detail in [SECURITY.md](SECURITY.md).

- **Rootless Podman.** Runs in a user namespace (`--userns=keep-id`) with `--cap-drop=ALL`, only the few capabilities the image needs at init, `no-new-privileges`, 1 CPU, 5 GB memory and 256 processes.
- **One projects folder.** Only the folder that contains this repo (`~/Projects` for me) is mounted read/write (as `/workspace/projects`), plus the assistant's own data and export folders. The rest of `$HOME`, `~/.ssh`, browser profiles and any host Hermes/Codex installs are not mounted.
- **systemd user service.** `hermes-assistant.service` runs as my user, not root, always restarts (`Restart=always`) and logs to journald. Lingering keeps it up after reboot.
- **Emergency stop.** `./scripts/emergency-stop.sh` stops the service and the container. `systemctl --user disable hermes-assistant.service` keeps it from coming back.
- **Credentials.** Everything lives in `~/.local/share/hermes-assistant/` (`.env` and `auth.json` are `0600`, the Codex dir is `0700`). The Telegram token is read with a hidden prompt and never printed. OAuth uses device codes. Nothing secret goes in the repo. `.env.example` only lists empty variable names.
- **Telegram lockdown.** Deny by default, allowed for one numeric user ID found during setup. Messages from anyone else are ignored and pairing is off.

## Tests

There's no automated test suite. [TESTING.md](TESTING.md) is a manual checklist with the current status of each capability. Container isolation, service restart and the credential scan pass. Most end-to-end messaging checks are still marked BLOCKED.

## Limitations

- Everything next to this repo in its parent folder is visible to the agent, so keep that folder to projects only.
- Discord and email are configured but turned off until their approval checks are verified.

## License

MIT. See [LICENSE](LICENSE).
