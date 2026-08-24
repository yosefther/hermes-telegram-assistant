# Capability Test Checklist

Status values: `PASS`, `FAIL`, or `BLOCKED`.

| Test | Status | Evidence |
|---|---|---|
| Deployment shell scripts parse | PASS | `bash -n scripts/*.sh` passed for all scripts. |
| Existing runtime cwd migrates to projects tree | BLOCKED | Run `./scripts/bootstrap.sh`, then verify the saved config uses `/workspace/projects/personal assesteant`. |
| Hermes YAML parses at schema v38 | PASS | Parsed with the installed Hermes Python environment and asserted `_config_version: 38`. |
| User service unit validates and is enabled | PASS | `systemd-analyze --user verify` passed; `systemctl --user is-enabled` returned `enabled`. |
| Rootless container starts as intended | PASS | Official image started under rootless Podman; Hermes runtime identity was `uid=10000(hermes)`. |
| Hermes CLI responds through OpenAI Codex OAuth | BLOCKED | OAuth credentials exist in the isolated data directory; a live model response remains to be tested. |
| Memory persists across sessions | BLOCKED | Gateway is running; a two-session recall test remains. |
| Unauthorized Telegram account is denied | BLOCKED | Owner allowlist is configured for numeric ID `1690763378`; denial from a second account remains to be tested. |
| Authorized Telegram chat works | BLOCKED | Hermes runtime reports Telegram `connected` with no error; an end-to-end owner message/reply remains to be tested. |
| Telegram file, image, and voice handling | BLOCKED | Telegram is connected and ffmpeg is installed; end-to-end media tests remain. |
| Web browsing returns cited sources | BLOCKED | Provider authentication not completed. |
| Approved projects tree can be inspected | BLOCKED | The mount is configured as `/home/user/Projects:/workspace/projects:rw`; verify it after redeploying the runtime configuration. |
| Files in sibling projects can be read and written | BLOCKED | Requires a controlled test file in a sibling project after redeploying. |
| Outside directory cannot be accessed | PASS | `/home/user/.ssh` was not visible inside the container. |
| Branch, test edit, and tests work | BLOCKED | Requires explicit branch/edit approval for the controlled test. |
| Codex delegation succeeds | BLOCKED | Isolated Codex CLI 0.149.0 and OAuth credentials are installed; a delegated test remains. |
| Email drafts but cannot send without approval | BLOCKED | Email intentionally disabled pending enforcement verification. |
| Discord drafts but cannot send without approval | BLOCKED | Bot token and numeric user identity not configured. |
| Repository contains no credential values | PASS | Pattern scan found no credential value; `.env.example` contains empty names only. Re-test after runtime secret entry. |
| Gateway restarts after failure | PASS | The enabled user unit restarted the rootless container and returned to `active`; Telegram returned to `connected`. |
| User service is enabled across reboot | PASS | The user unit is enabled and `loginctl show-user` reports lingering enabled. |
