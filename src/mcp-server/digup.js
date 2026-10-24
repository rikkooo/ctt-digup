/**
 * digup.js — thin, injection-safe wrapper around the `digup` CLI.
 *
 * Rules (card 04):
 *  - Always invoke the digup binary with a spawn/execFile **argument array**.
 *    Never build a shell string. No `shell: true`. This prevents command
 *    injection from folder names, queries, or any other user-controlled arg.
 *  - Binary path comes from `DIGUP_BIN`, else platform defaults
 *    (POSIX: /usr/local/bin/digup; Windows: <install>\helper\digup.exe —
 *    see resolveDigupCommand() and WINDOWS_FALLBACK_BINS).
 *  - Pass `--json` where the subcommand supports it and parse JSON / NDJSON.
 *  - Cap captured stdout/stderr at ~50 KB per invocation (OUTPUT_CAP_BYTES).
 *
 * Optional (Windows host → WSL engine):
 *  - Set `DIGUP_WSL_DISTRO` (e.g. "Ubuntu-26.04") to run the digup binary
 *    inside that WSL distro via `wsl.exe -d <distro> -- <bin> <args...>`.
 *    Still an argv array — no shell interpolation on either side.
 */

import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

/** Hard cap on captured tool output (~50 KB). */
export const OUTPUT_CAP_BYTES = 50 * 1024;

/** Default CLI binary on Linux / WSL / macOS. */
export const DEFAULT_POSIX_BIN = "/usr/local/bin/digup";

/**
 * Documented Windows fallback locations. First existing candidate wins when
 * DIGUP_BIN is unset on win32.
 *
 * NOTE: the developer CLI is the binary in the `helper\` subdirectory
 * (`helper\digup.exe`) — same interface as the Linux/WSL `digup`. The
 * top-level `digup.exe` next to `DigUp.exe` is the app's internal
 * "digup-shell" and does NOT implement the CLI subcommands; never pick it.
 */
export const WINDOWS_FALLBACK_BINS = [
  join(process.env.LOCALAPPDATA || "", "DigUp", "helper", "digup.exe"),
  "C:\\Program Files\\DigUp\\helper\\digup.exe",
  "C:\\Program Files (x86)\\DigUp\\helper\\digup.exe",
  join(process.env.LOCALAPPDATA || "", "Programs", "DigUp", "helper", "digup.exe"),
];

/** Default timeouts (ms). Overridable with DIGUP_TIMEOUT_MS. */
const DEFAULT_TIMEOUT_MS = 120_000;
const LONG_TIMEOUT_MS = 900_000; // index / download-model

/**
 * Resolve how to invoke digup.
 * @returns {{ file: string, prefixArgs: string[], bin: string }}
 *   `file` + `prefixArgs` are prepended to the digup subcommand args.
 */
export function resolveDigupCommand() {
  const wslDistro = process.env.DIGUP_WSL_DISTRO;
  if (process.platform === "win32" && wslDistro) {
    // Route through WSL. DIGUP_BIN is interpreted *inside* the distro.
    const bin = process.env.DIGUP_BIN || DEFAULT_POSIX_BIN;
    return { file: "wsl.exe", prefixArgs: ["-d", wslDistro, "--", bin], bin };
  }

  if (process.env.DIGUP_BIN) {
    return { file: process.env.DIGUP_BIN, prefixArgs: [], bin: process.env.DIGUP_BIN };
  }

  if (process.platform === "win32") {
    for (const candidate of WINDOWS_FALLBACK_BINS) {
      if (candidate && existsSync(candidate)) {
        return { file: candidate, prefixArgs: [], bin: candidate };
      }
    }
    // Nothing found: use the documented default so the ENOENT error names it.
    const fallback = WINDOWS_FALLBACK_BINS[0];
    return { file: fallback, prefixArgs: [], bin: fallback };
  }

  return { file: DEFAULT_POSIX_BIN, prefixArgs: [], bin: DEFAULT_POSIX_BIN };
}

/**
 * Spawn the digup CLI with an argument array. Never uses a shell.
 *
 * @param {string[]} args  digup subcommand + flags (each element one argv).
 * @param {{ timeoutMs?: number, onStdoutLine?: (line: string) => void }} [opts]
 * @returns {Promise<{ stdout: string, stderr: string, code: number|null, signal: string|null, truncated: boolean, timedOut: boolean }>}
 */
export function runDigup(args, opts = {}) {
  if (!Array.isArray(args) || args.some((a) => typeof a !== "string")) {
    return Promise.reject(new Error("runDigup: args must be an array of strings"));
  }

  const { file, prefixArgs } = resolveDigupCommand();
  const argv = [...prefixArgs, ...args];
  const timeoutMs =
    opts.timeoutMs ??
    (Number.parseInt(process.env.DIGUP_TIMEOUT_MS || "", 10) || defaultTimeoutFor(args));

  return new Promise((resolve, reject) => {
    let child;
    try {
      child = spawn(file, argv, {
        stdio: ["ignore", "pipe", "pipe"],
        windowsHide: true,
        // Explicitly never use a shell — argv is passed verbatim.
        shell: false,
      });
    } catch (err) {
      reject(err);
      return;
    }

    let stdout = "";
    let stderr = "";
    let truncated = false;
    let totalOut = 0;
    let timedOut = false;
    let lineBuffer = "";

    const appendCapped = (chunk, which) => {
      totalOut += Buffer.byteLength(chunk);
      if (totalOut > OUTPUT_CAP_BYTES) {
        if (!truncated) {
          truncated = true;
          const keep = Math.max(0, OUTPUT_CAP_BYTES - Buffer.byteLength(stdout + stderr));
          const part = chunk.slice(0, keep);
          if (which === "out") stdout += part;
          else stderr += part;
        }
        return;
      }
      if (which === "out") stdout += chunk;
      else stderr += chunk;
    };

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");

    child.stdout.on("data", (chunk) => {
      appendCapped(chunk, "out");
      if (opts.onStdoutLine) {
        lineBuffer += chunk;
        let idx;
        while ((idx = lineBuffer.indexOf("\n")) >= 0) {
          const line = lineBuffer.slice(0, idx);
          lineBuffer = lineBuffer.slice(idx + 1);
          opts.onStdoutLine(line);
        }
      }
    });
    child.stderr.on("data", (chunk) => appendCapped(chunk, "err"));

    const timer = setTimeout(() => {
      timedOut = true;
      child.kill("SIGTERM");
      // Escalate if it ignores SIGTERM.
      setTimeout(() => {
        try {
          child.kill("SIGKILL");
        } catch {
          /* already gone */
        }
      }, 5_000).unref?.();
    }, timeoutMs);
    timer.unref?.();

    child.on("error", (err) => {
      clearTimeout(timer);
      reject(err);
    });

    child.on("close", (code, signal) => {
      clearTimeout(timer);
      if (opts.onStdoutLine && lineBuffer.length > 0) {
        opts.onStdoutLine(lineBuffer);
        lineBuffer = "";
      }
      resolve({ stdout, stderr, code, signal, truncated, timedOut });
    });
  });
}

function defaultTimeoutFor(args) {
  const cmd = args[0];
  if (cmd === "index" || cmd === "download-model") return LONG_TIMEOUT_MS;
  return DEFAULT_TIMEOUT_MS;
}

/**
 * Parse digup output: whole-document JSON, else NDJSON lines, else raw text.
 * @param {string} stdout
 * @returns {{ mode: 'json'|'ndjson'|'text', data: unknown, lines?: unknown[] }}
 */
export function parseDigupOutput(stdout) {
  const trimmed = (stdout || "").trim();
  if (!trimmed) return { mode: "text", data: "" };

  try {
    return { mode: "json", data: JSON.parse(trimmed) };
  } catch {
    /* not a single JSON document */
  }

  const lines = trimmed.split(/\r?\n/).filter((l) => l.trim() !== "");
  const parsed = [];
  let allJson = true;
  for (const line of lines) {
    try {
      parsed.push(JSON.parse(line));
    } catch {
      allJson = false;
      break;
    }
  }
  if (allJson && parsed.length > 0) {
    return { mode: "ndjson", data: parsed, lines: parsed };
  }

  return { mode: "text", data: stdout };
}

/** Cap a string to OUTPUT_CAP_BYTES UTF-8 bytes and mark truncation. */
export function capText(text, cap = OUTPUT_CAP_BYTES) {
  const buf = Buffer.from(String(text ?? ""), "utf8");
  if (buf.length <= cap) return { text: String(text ?? ""), truncated: false };
  return {
    text: buf.subarray(0, cap).toString("utf8") + "\n…[truncated at ~50 KB]",
    truncated: true,
  };
}

/**
 * High-level: run digup and return a structured result for tool handlers.
 * @param {string[]} args
 * @param {{ timeoutMs?: number }} [opts]
 */
export async function digup(args, opts = {}) {
  const started = Date.now();
  let res;
  try {
    res = await runDigup(args, opts);
  } catch (err) {
    return {
      ok: false,
      error: `failed to spawn digup (${resolveDigupCommand().bin}): ${err.message}`,
      args,
      durationMs: Date.now() - started,
    };
  }

  const parsed = parseDigupOutput(res.stdout);
  const stderrCap = capText(res.stderr);

  if (res.timedOut) {
    return {
      ok: false,
      error: `digup ${args[0] ?? ""} timed out`,
      args,
      stdout: capText(res.stdout).text,
      stderr: stderrCap.text,
      durationMs: Date.now() - started,
    };
  }

  if (res.code !== 0) {
    return {
      ok: false,
      error: `digup exited with code ${res.code}${res.signal ? ` (signal ${res.signal})` : ""}`,
      args,
      stdout: capText(res.stdout).text,
      stderr: stderrCap.text,
      exitCode: res.code,
      durationMs: Date.now() - started,
    };
  }

  return {
    ok: true,
    args,
    mode: parsed.mode,
    data: parsed.data,
    stdout: capText(res.stdout).text,
    stderr: stderrCap.text,
    truncated: res.truncated,
    durationMs: Date.now() - started,
  };
}

// ── Tool-facing helpers (map MCP tool inputs → digup argv arrays) ──────────

const SEARCH_KINDS = new Set(["screenshot", "image", "pdf", "doc", "audio", "video"]);

/** digup_search → `digup search <query> [-n N] [--kind K,K] --json` */
export async function digupSearch({ query, limit, kind, code } = {}) {
  const q = String(query ?? "").trim();
  if (!q) return { ok: false, error: "query must be a non-empty string" };

  const args = ["search"];

  // `code: <words>` is digup's documented way to search the code index.
  // If the caller passes code:true and the query has no prefix, add it.
  let effectiveQuery = q;
  if (code === true && !/^\s*code:/i.test(q)) {
    effectiveQuery = `code: ${q}`;
  }

  args.push(effectiveQuery);

  if (limit !== undefined && limit !== null) {
    const n = Number(limit);
    if (!Number.isInteger(n) || n < 1 || n > 200) {
      return { ok: false, error: "limit must be an integer in 1..200" };
    }
    args.push("-n", String(n));
  }

  if (kind !== undefined && kind !== null) {
    if (!Array.isArray(kind) || kind.some((k) => typeof k !== "string" || !k.trim())) {
      return { ok: false, error: "kind must be an array of non-empty strings" };
    }
    for (const k of kind) {
      if (!SEARCH_KINDS.has(k.trim().toLowerCase())) {
        return {
          ok: false,
          error: `unknown kind "${k}" (allowed: ${[...SEARCH_KINDS].join(", ")})`,
        };
      }
    }
    args.push("--kind", kind.map((k) => k.trim().toLowerCase()).join(","));
  }

  args.push("--json");
  return digup(args);
}

/** digup_index → `digup index <folder>... [--code]` (text output; no --json) */
export async function digupIndex({ folders, code } = {}) {
  if (!Array.isArray(folders) || folders.length === 0) {
    return { ok: false, error: "folders must be a non-empty array of strings" };
  }
  if (folders.some((f) => typeof f !== "string" || !f.trim())) {
    return { ok: false, error: "folders must contain non-empty strings" };
  }

  const args = ["index", ...folders.map((f) => f.trim())];
  if (code === true) args.push("--code");
  return digup(args);
}

/** digup_estimate → `digup estimate <folder>... --json` (NDJSON when >1 folder) */
export async function digupEstimate({ folders } = {}) {
  if (!Array.isArray(folders) || folders.length === 0) {
    return { ok: false, error: "folders must be a non-empty array of strings" };
  }
  if (folders.some((f) => typeof f !== "string" || !f.trim())) {
    return { ok: false, error: "folders must contain non-empty strings" };
  }

  const args = ["estimate", ...folders.map((f) => f.trim()), "--json"];
  return digup(args);
}

/** digup_status → `digup status` (human text; status has no --json mode) */
export async function digupStatus() {
  return digup(["status"]);
}

/**
 * digup_download_model → `digup download-model` (NDJSON event stream:
 * {"event":"file"|"progress"|"done", ...}). We keep the first and last events
 * plus a count so a long download cannot blow past the output cap.
 */
export async function digupDownloadModel() {
  const events = [];
  let progressCount = 0;
  let lastProgress = null;

  const onStdoutLine = (line) => {
    const t = line.trim();
    if (!t) return;
    let obj;
    try {
      obj = JSON.parse(t);
    } catch {
      return;
    }
    if (obj.event === "progress") {
      progressCount += 1;
      lastProgress = obj;
      return;
    }
    events.push(obj);
  };

  const res = await runDigup(["download-model"], {
    timeoutMs: Number.parseInt(process.env.DIGUP_TIMEOUT_MS || "", 10) || LONG_TIMEOUT_MS,
    onStdoutLine,
  });

  const summary = {
    events,
    progress_events: progressCount,
    last_progress: lastProgress,
    exitCode: res.code,
    timedOut: res.timedOut,
    truncated: res.truncated,
    stderr: capText(res.stderr).text,
    durationMs: undefined,
  };

  if (res.timedOut) {
    return { ok: false, error: "digup download-model timed out", data: summary };
  }
  if (res.code !== 0) {
    return {
      ok: false,
      error: `digup download-model exited with code ${res.code}`,
      data: summary,
    };
  }
  return { ok: true, mode: "ndjson", data: summary, stdout: "", stderr: summary.stderr };
}
