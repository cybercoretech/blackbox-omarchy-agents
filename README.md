# Blackbox Omarchy Agents

User-owned Omarchy Agents widget customization for local usage and
authoritative quota display.

## Contents

- `omarchy/plugins/raven.agents/` — cloned, update-safe widget plugin.
- `omarchy/bin/` — Copilot and Antigravity/extra-agent collectors.
- `omarchy/systemd/user/` — user timers and services for collectors.
- `vscode/copilot-quota-bridge/` — local VS Code extension source for the
  authenticated Copilot quota bridge.
- `config/raven.agents.shell-entry.json` — portable provider configuration
  entry, not a complete machine-specific `shell.json`.

## Install

Copy the plugin to `~/.config/omarchy/plugins/raven.agents`, the collectors
to `~/.local/bin`, the systemd units to `~/.config/systemd/user`, and the
quota bridge source to `~/.local/share/copilot-quota-bridge`. Merge the
configuration entry into `~/.config/omarchy/shell.json`; do not replace that
file because it contains machine-specific bar and provider settings.

After installing:

```bash
systemctl --user daemon-reload
systemctl --user enable --now omarchy-extra-agent-usage.timer
systemctl --user enable --now omarchy-copilot-usage.timer
omarchy-shell raven.agents refresh
```

Do not commit `~/.local/state/omarchy/agents/usage`, agent databases,
OAuth/keyring data, quota snapshots, or backup files. They are local runtime
data and may contain sensitive information.

See `omarchy/plugins/raven.agents/README.md` for provider setup and collector
details.
