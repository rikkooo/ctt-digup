#!/usr/bin/env node
/**
 * index.js — DigUp MCP server (stdio).
 *
 * Exposes five tools over the Model Context Protocol so any MCP-capable
 * agent can search/index/estimate/status/download-model via the digup CLI.
 *
 * Transport: stdio (newline-delimited JSON-RPC). stdout carries protocol
 * messages only — diagnostics go to stderr.
 *
 * See docs/MCP.md for tool schemas and example responses.
 * See mcp.json at the repo root for a ready-to-paste client config.
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

import {
  capText,
  digupSearch,
  digupIndex,
  digupEstimate,
  digupStatus,
  digupDownloadModel,
  resolveDigupCommand,
  OUTPUT_CAP_BYTES,
} from "./digup.js";

const SERVER_NAME = "digup-mcp";
const SERVER_VERSION = "0.1.0";

const server = new McpServer({
  name: SERVER_NAME,
  version: SERVER_VERSION,
});

/** Serialize a tool result, always capped at ~50 KB. */
function textResult(payload) {
  const raw = typeof payload === "string" ? payload : JSON.stringify(payload, null, 2);
  const { text } = capText(raw, OUTPUT_CAP_BYTES);
  return { content: [{ type: "text", text }] };
}

function errorResult(message, extra) {
  const body = { error: String(message), ...(extra && typeof extra === "object" ? extra : {}) };
  return { isError: true, ...textResult(body) };
}

/** Normalise a digup.js result into MCP content. */
function fromDigup(result, { textMode = false } = {}) {
  if (!result || result.ok === false) {
    return errorResult(result?.error || "digup failed", {
      args: result?.args,
      exitCode: result?.exitCode,
      stdout: result?.stdout,
      stderr: result?.stderr,
    });
  }
  if (textMode) {
    return textResult({ ok: true, output: result.stdout, truncated: result.truncated ?? false });
  }
  return textResult({
    ok: true,
    mode: result.mode,
    data: result.data,
    truncated: result.truncated ?? false,
    ...(result.stderr ? { stderr: result.stderr } : {}),
  });
}

// ── Tools ─────────────────────────────────────────────────────────────────

server.registerTool(
  "digup_search",
  {
    title: "DigUp semantic search",
    description:
      "Search indexed files by meaning using DigUp. " +
      'Pass code:true (or prefix the query with "code: ") to search the code index. ' +
      "kind filters by file kind (screenshot, image, pdf, doc, audio, video). " +
      "Maps to `digup search <query> -n <limit> --kind <k,k> --json`.",
    inputSchema: {
      query: z.string().min(1).describe("Natural-language search query, e.g. 'invoice from last March'"),
      limit: z.number().int().min(1).max(200).optional().describe("Max results (digup -n). Default 10."),
      kind: z
        .array(z.enum(["screenshot", "image", "pdf", "doc", "audio", "video"]))
        .optional()
        .describe("Optional file-kind filter (digup --kind)"),
      code: z
        .boolean()
        .optional()
        .describe("Search the code index (prepends 'code: ' to the query)"),
    },
  },
  async ({ query, limit, kind, code }) => fromDigup(await digupSearch({ query, limit, kind, code }))
);

server.registerTool(
  "digup_index",
  {
    title: "DigUp index folders",
    description:
      "Sync the DigUp index with one or more folders: discover new/changed files, embed what's new. " +
      "code:true also builds/updates the code index (source files, minus what git ignores). " +
      "Long-running. Maps to `digup index <folder>... [--code]`.",
    inputSchema: {
      folders: z.array(z.string().min(1)).min(1).describe("Absolute folder paths to index"),
      code: z.boolean().optional().describe("Also index the code index (digup --code)"),
    },
  },
  async ({ folders, code }) => fromDigup(await digupIndex({ folders, code }), { textMode: true })
);

server.registerTool(
  "digup_estimate",
  {
    title: "DigUp estimate indexing cost",
    description:
      "Estimate what would be indexed for each folder and how long the first pass takes. " +
      "Returns one JSON object per folder. Maps to `digup estimate <folder>... --json`.",
    inputSchema: {
      folders: z.array(z.string().min(1)).min(1).describe("Absolute folder paths to estimate"),
    },
  },
  async ({ folders }) => fromDigup(await digupEstimate({ folders }))
);

server.registerTool(
  "digup_status",
  {
    title: "DigUp index status",
    description:
      "Report what's in the DigUp index (index path, vector count, size, build info). " +
      "Takes no arguments. Maps to `digup status`.",
    inputSchema: {},
  },
  async () => fromDigup(await digupStatus(), { textMode: true })
);

server.registerTool(
  "digup_download_model",
  {
    title: "DigUp download embedding model",
    description:
      "Download the EmbeddingGemma 2 embedding model (~865 MB) with resume support. " +
      "Returns a summary of the NDJSON event stream (file/progress/done events). " +
      "Long-running. Maps to `digup download-model`.",
    inputSchema: {},
  },
  async () => fromDigup(await digupDownloadModel())
);

// ── stdio transport ───────────────────────────────────────────────────────

async function main() {
  const cmd = resolveDigupCommand();
  console.error(
    `[${SERVER_NAME}] v${SERVER_VERSION} starting; digup=${cmd.bin}` +
      (cmd.prefixArgs.length ? ` (via ${cmd.file} ${cmd.prefixArgs.slice(0, 2).join(" ")})` : "")
  );
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error(`[${SERVER_NAME}] connected on stdio`);
}

main().catch((err) => {
  console.error(`[${SERVER_NAME}] fatal:`, err);
  process.exit(1);
});
