# Security Model

Hermes runs as an unprivileged user inside a rootless Podman user namespace. The container receives only three writable bind mounts: its dedicated state directory, the explicitly approved `/home/user/Projects` tree, and an export directory. The projects tree is available at `/workspace/projects`, including all of its files and subdirectories. The rest of the host home directory, browser profile, SSH directory, and existing Hermes/Codex installations are not mounted.

The container is the primary security boundary. Prompt rules, tool allowlists, and approval prompts are additional safeguards, not containment boundaries.

## Credentials

- Runtime state: `~/.local/share/hermes-assistant/`
- Gateway secrets: `~/.local/share/hermes-assistant/.env` (`0600`)
- Hermes OAuth: `~/.local/share/hermes-assistant/auth.json` (`0600`)
- Codex OAuth: `~/.local/share/hermes-assistant/codex/` (`0700`)
- Secrets must never be copied into this repository, logs, prompts, command arguments, or chat.
- Telegram and OAuth setup scripts accept hidden input or device-code authorization.

## Network and messaging

- Telegram is deny-by-default and restricted to one discovered numeric user ID.
- Unauthorized direct messages are silently ignored; pairing is disabled.
- Discord remains disabled until its token and an authoritative user allowlist are configured. Channel IDs alone do not establish identity.
- Email remains disabled until outbound confirmation enforcement is verified. The email gateway's automatic reply behavior must not bypass the approval policy.
- The browser uses a separate container profile. It has no access to existing host-browser cookies or sessions.

## Outbound approval policy

Research, reading, searching, and drafting do not require confirmation. Sending messages or email, public posting, uploads, authenticated-browser actions, commits, pushes, dependency changes, migrations, deployments, destructive commands, and account/financial/security actions require explicit single-use approval.

## Runtime limits

- One active Hermes session at a time.
- One CPU, 5 GiB memory, and 256 process limit.
- Terminal, code-execution, agent-turn, and tool-loop limits are configured in `config/hermes-config.yaml`.
- Container capabilities are dropped and only the minimum init-time capabilities required by the official image are restored inside the rootless user namespace.

## Logs

View service logs:

```bash
journalctl --user -u hermes-assistant.service -f
```

Hermes also maintains rotated gateway logs under `~/.local/share/hermes-assistant/logs/`. Do not paste logs publicly without checking them for private message content and identifiers.

## Emergency shutdown

```bash
./scripts/emergency-stop.sh
```

To prevent automatic restart until investigation is complete:

```bash
systemctl --user disable hermes-assistant.service
```
