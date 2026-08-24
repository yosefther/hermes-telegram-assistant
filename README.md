# Secure Hermes Personal Assistant

This deployment runs the official Hermes Agent image in rootless Podman with `/home/user/Projects` mounted read/write at `/workspace/projects`. Hermes starts in `/workspace/projects/personal assesteant` and can work with every file and directory below the projects root. The rest of the host home directory remains unavailable. Telegram is the primary interface. Discord and email remain disabled until their approval and identity controls are completed.

## Initial setup

Run these commands from this directory:

```bash
./scripts/install-prerequisites.sh
./scripts/bootstrap.sh
./scripts/secure-telegram-setup.sh
./scripts/auth-codex.sh
```

The first command requests your sudo password locally. The Telegram token prompt is hidden. Codex uses device-code OAuth; never paste its cached credentials into chat.

After authentication, perform foreground validation before starting the service:

```bash
./scripts/container-command.sh hermes doctor
./scripts/container-command.sh hermes
```

Then start the gateway:

```bash
systemctl --user start hermes-assistant.service
```

After upgrading an existing single-project installation, run `./scripts/bootstrap.sh` once to migrate the saved terminal working directory, then restart the service. Bootstrap keeps all other existing Hermes configuration values.

## Operations

```bash
systemctl --user status hermes-assistant.service
systemctl --user stop hermes-assistant.service
systemctl --user restart hermes-assistant.service
journalctl --user -u hermes-assistant.service -f
./scripts/emergency-stop.sh
```

## Update

Updates are manual and require confirmation:

```bash
podman pull docker.io/nousresearch/hermes-agent:latest
systemctl --user restart hermes-assistant.service
```

Review release notes and back up first. Do not update while an agent or Codex task is running.

## Backup and restore

Stop the service before backup:

```bash
systemctl --user stop hermes-assistant.service
tar --create --gzip --file "$HOME/hermes-assistant-backup.tgz" --directory "${XDG_DATA_HOME:-$HOME/.local/share}" hermes-assistant
```

The archive contains credentials and must be encrypted and protected like a password. Restore only into `~/.local/share/hermes-assistant` while the service is stopped, then restore directory/file modes before starting.

## Troubleshooting

```bash
podman ps --all --filter name=hermes-assistant
podman logs hermes-assistant
./scripts/container-command.sh hermes doctor
./scripts/container-command.sh hermes auth status openai-codex
./scripts/container-command.sh codex login status
```

If rootless Podman reports UID-map errors, verify `uidmap` is installed and `/etc/subuid` and `/etc/subgid` contain ranges for your account. If the user service cannot start after reboot, verify `loginctl show-user "$USER" -p Linger` reports `yes`.

## Current completion state

See [TESTING.md](TESTING.md). No capability is considered complete until its corresponding test has been executed successfully.
