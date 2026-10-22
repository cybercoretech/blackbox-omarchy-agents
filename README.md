# 🤖 Blackbox Omarchy Agents

User-owned Omarchy Agents widget customization for local usage and
authoritative quota display.

## 📦 Contents

- `omarchy/plugins/raven.agents/` — cloned, update-safe widget plugin.
- `omarchy/bin/` — Copilot and Antigravity/extra-agent collectors.
- `omarchy/systemd/user/` — user timers and services for collectors.
- `vscode/copilot-quota-bridge/` — local VS Code extension source for the
  authenticated Copilot quota bridge.
- `config/raven.agents.shell-entry.json` — portable provider configuration
  entry, not a complete machine-specific `shell.json`.

## 🛠️ Install

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

## ✅ Tests

Run `./scripts/test-local.sh` before committing. It validates the collector
fixtures, JSON contracts, source syntax, configuration, and documentation.

Do not commit `~/.local/state/omarchy/agents/usage`, agent databases,
OAuth/keyring data, quota snapshots, or backup files. They are local runtime
data and may contain sensitive information.

See `omarchy/plugins/raven.agents/README.md` for provider setup and collector
details.

## 🖥️ Standalone dashboard

The full Cyberdeck/Mission Control view is available as a separate Quickshell
window while the bar widget remains a compact launcher:

```bash
omarchy-shell shell toggle raven.agents-dashboard
omarchy-shell shell open raven.agents-dashboard
omarchy-shell shell close raven.agents-dashboard
```

The window uses a compact three-column provider grid, provider scope selector,
quota meters, local-activity labels, refresh controls, and keyboard shortcuts.
Its palette follows the Cybercore schema: `#07090e` background, `#111821`
panels, `#3a4656` dividers, cyan grid lines, acid-green healthy states, and
hot-pink headings. Provider rows use sharp, bordered cards with compact
telemetry labels rather than an unstructured vertical list.
The compact bar dropdown uses the same palette for its telemetry and provider
states.

## 🔭 Future agents

The widget maintains a configurable catalog of likely future CLIs. It probes
their executable names and lists installed candidates under **Inactive agents**
until a real collector produces usage data. Installation alone never creates a
quota meter or percentage.
