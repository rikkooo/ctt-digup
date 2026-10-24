#!/usr/bin/env node
/**
 * smoke-test.js — minimal MCP stdio client smoke test.
 *
 * Spawns `node index.js`, then exercises:
 *   1. initialize
 *   2. tools/list  (expects all five digup_* tools)
 *   3. tools/call  digup_status (and optionally digup_estimate / digup_search)
 *
 * Usage:
 *   node smoke-test.js                # initialize + tools/list + digup_status
 *   node smoke-test.js --full         # also digup_estimate + digup_search
 *   node smoke-test.js --call NAME    # single tools/call after list
 *
 * Exit code 0 = all checks passed.
 */

import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SERVER = join(__dirname, "index.js");

const args = process.argv.slice(2);
const full = args.includes("--full");
const callOnly = args.includes("--call") ? args[args.indexOf("--call") + 1] : null;

function rpc(id, method, params) {
  return JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n";
}
function notify(method, params) {
  return JSON.stringify({ jsonrpc: "2.0", method, params }) + "\n";
}

class Client {
  constructor(child) {
    this.child = child;
    this.nextId = 10;
    this.pending = new Map();
    this.buffer = "";
    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
      this.buffer += chunk;
      let idx;
      while ((idx = this.buffer.indexOf("\n")) >= 0) {
        const line = this.buffer.slice(0, idx).trim();
        this.buffer = this.buffer.slice(idx + 1);
        if (!line) continue;
        let msg;
        try {
          msg = JSON.parse(line);
        } catch {
          console.error("  [non-JSON line from server]", line.slice(0, 200));
          continue;
        }
        if (msg.id !== undefined && this.pending.has(msg.id)) {
          const { resolve, reject } = this.pending.get(msg.id);
          this.pending.delete(msg.id);
          if (msg.error) reject(new Error(JSON.stringify(msg.error)));
          else resolve(msg.result);
        }
      }
    });
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (c) => process.stderr.write(`  [server] ${c}`));
  }

  send(obj) {
    this.child.stdin.write(JSON.stringify(obj) + "\n");
  }

  request(method, params) {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.send({ jsonrpc: "2.0", id, method, params });
      setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`timeout waiting for ${method}`));
        }
      }, 60_000).unref?.();
    });
  }

  notify(method, params) {
    this.send({ jsonrpc: "2.0", method, params });
  }
}

function assert(cond, label) {
  if (cond) {
    console.log(`  PASS  ${label}`);
    return true;
  }
  console.error(`  FAIL  ${label}`);
  return false;
}

async function main() {
  console.log(`smoke-test: spawning ${SERVER}`);
  const child = spawn(process.execPath, [SERVER], {
    stdio: ["pipe", "pipe", "pipe"],
    env: process.env,
  });

  const client = new Client(child);
  let failed = false;

  try {
    // 1. initialize
    const init = await client.request("initialize", {
      protocolVersion: "2025-06-18",
      capabilities: {},
      clientInfo: { name: "digup-smoke", version: "0.0.1" },
    });
    console.log("initialize →", JSON.stringify(init.serverInfo ?? init, null, 2).slice(0, 400));
    failed = !assert(init?.serverInfo?.name === "digup-mcp", "initialize returns digup-mcp serverInfo") || failed;
    client.notify("notifications/initialized", {});

    // 2. tools/list
    const list = await client.request("tools/list", {});
    const names = (list.tools || []).map((t) => t.name).sort();
    console.log("tools/list →", names);
    const expected = [
      "digup_download_model",
      "digup_estimate",
      "digup_index",
      "digup_search",
      "digup_status",
    ];
    failed = !assert(
      expected.every((n) => names.includes(n)),
      `tools/list exposes all five tools (got: ${names.join(", ")})`
    ) || failed;

    // 3. tools/call
    const calls = [];
    if (callOnly) {
      calls.push([callOnly, callOnly === "digup_search" ? { query: "project mission" } : {}]);
    } else {
      calls.push(["digup_status", {}]);
      if (full) {
        calls.push(["digup_estimate", { folders: ["/tmp/digup-smoke"] }]);
        calls.push(["digup_search", { query: "project mission roadmap", limit: 3 }]);
      }
    }

    for (const [name, toolArgs] of calls) {
      const res = await client.request("tools/call", { name, arguments: toolArgs });
      const text = res?.content?.[0]?.text ?? JSON.stringify(res);
      console.log(`tools/call ${name} → isError=${Boolean(res?.isError)}`);
      console.log(String(text).slice(0, 600));
      failed = !assert(res?.content?.length > 0, `tools/call ${name} returns content`) || failed;
    }
  } catch (err) {
    failed = true;
    console.error("smoke-test error:", err.message);
  } finally {
    child.kill();
  }

  if (failed) {
    console.error("smoke-test: FAILED");
    process.exit(1);
  }
  console.log("smoke-test: OK");
}

main();
