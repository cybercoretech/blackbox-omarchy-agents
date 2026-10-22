"use strict";

const vscode = require("vscode");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const API_URL = "https://api.github.com/copilot_internal/user";
const API_SCOPES = ["user:email"];
const REFRESH_MS = 5 * 60 * 1000;

function outputPath() {
  const stateHome = process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local", "state");
  return path.join(stateHome, "omarchy", "agents", "copilot-quota.json");
}

function pickQuota(data) {
  const snapshots = data && data.quota_snapshots;
  if (!snapshots || typeof snapshots !== "object") return null;

  const priority = ["premium_interactions", "premium_requests", "chat", "completions"];
  const names = {
    premium_interactions: "Premium Requests",
    premium_requests: "Premium Requests",
    chat: "Chat",
    completions: "Completions",
  };

  for (const key of priority) {
    const snapshot = snapshots[key];
    if (!snapshot || typeof snapshot !== "object") continue;
    const used = Number(snapshot.credits_used);
    const total = Number(snapshot.entitlement);
    if (!Number.isFinite(used) || !Number.isFinite(total) || (used <= 0 && total <= 0)) continue;

    const remaining = Number(snapshot.remaining);
    const percentRemaining = Number(snapshot.percent_remaining);
    const exhausted = Number.isFinite(remaining)
      ? remaining <= 0
      : Number.isFinite(percentRemaining)
        ? percentRemaining <= 0
        : !snapshot.has_quota;
    const label = exhausted
      ? `No more ${names[key]} available`
      : `${names[key]} ${Math.round(used).toLocaleString()}/${Math.round(total).toLocaleString()} used`;
    const limit = {
      label,
      title: label,
      percent: exhausted ? 1 : (total > 0 ? Math.min(used / total, 1) : 0),
      used,
      total,
      unit: names[key].toLowerCase(),
    };
    const reset = data.quota_reset_date_utc;
    if (typeof reset === "string" && reset.length <= 64) limit.resetsAt = reset;
    return limit;
  }
  return null;
}

function writeQuota(record) {
  const target = outputPath();
  const dir = path.dirname(target);
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  if (fs.lstatSync(dir).isSymbolicLink()) throw new Error("Quota output directory is a symlink");
  try {
    if (fs.lstatSync(target).isSymbolicLink()) throw new Error("Quota output file is a symlink");
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  const temporary = `${target}.${process.pid}.${Date.now()}.tmp`;
  try {
    fs.writeFileSync(temporary, JSON.stringify(record, null, 2) + "\n", { mode: 0o600, flag: "wx" });
    fs.renameSync(temporary, target);
  } finally {
    try { fs.unlinkSync(temporary); } catch {}
  }
}

async function refresh(createIfNone) {
  try {
    const session = await vscode.authentication.getSession("github", API_SCOPES, { createIfNone });
    if (!session) return;

    const response = await fetch(API_URL, {
      headers: {
        Authorization: `Bearer ${session.accessToken}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "Omarchy-Copilot-Quota-Bridge",
      },
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error(`GitHub quota request returned HTTP ${response.status}`);

    const data = await response.json();
    const limit = pickQuota(data);
    if (!limit) return;

    writeQuota({
      schemaVersion: 1,
      updatedAt: new Date().toISOString(),
      plan: typeof data.copilot_plan === "string" ? data.copilot_plan : "Copilot",
      limit,
    });
  } catch (error) {
    console.warn("Copilot Quota Bridge could not refresh quota:", error && error.message ? error.message : "unknown error");
  }
}

function activate(context) {
  void refresh(true);
  const timer = setInterval(() => void refresh(false), REFRESH_MS);
  context.subscriptions.push({ dispose: () => clearInterval(timer) });
  context.subscriptions.push(
    vscode.commands.registerCommand("copilotQuotaBridge.refresh", () => refresh(true)),
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
