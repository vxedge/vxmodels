#!/usr/bin/env node
// validate-sysml.mjs: headless SysML v2 parse/typing gate (the model half of the
// double gate, sysml-authoring skill).
//
// Drives the SysIDE language server (Sensmetry sysml-2ls) over LSP stdio: opens
// every .sysml file passed on the command line, collects publishDiagnostics, and
// exits non-zero if any file produces an error-severity diagnostic. SysIDE has no
// one-shot CLI mode (LSP only), hence this driver. No npm dependencies: plain
// JSON-RPC over stdio.
//
// Usage:
//   SYSIDE_JS=/path/to/syside-languageserver.js \
//   SYSML_STDLIB=/path/to/sysml.library \
//   node scripts/validate-sysml.mjs models/**/*.sysml
//
// Pinned toolchain (docs/TESTBED-SETUP.md Tier M): SysIDE 0.9.1,
// SysML-v2-Release 2026-04 sysml.library.

import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const SYSIDE_JS = process.env.SYSIDE_JS;
const STDLIB = process.env.SYSML_STDLIB ?? "";
const files = process.argv.slice(2);
if (!SYSIDE_JS || files.length === 0) {
  console.error("usage: SYSIDE_JS=<syside-languageserver.js> [SYSML_STDLIB=<sysml.library>] node validate-sysml.mjs <files...>");
  process.exit(2);
}

const server = spawn("node", [SYSIDE_JS, "--stdio"], { stdio: ["pipe", "pipe", "inherit"] });
let nextId = 1;
const pending = new Map();

function send(msg) {
  const body = JSON.stringify(msg);
  server.stdin.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`);
}
function request(method, params) {
  const id = nextId++;
  send({ jsonrpc: "2.0", id, method, params });
  return new Promise((res) => pending.set(id, res));
}
function notify(method, params) {
  send({ jsonrpc: "2.0", method, params });
}

// diagnostics per URI; SysIDE (Langium) publishes after didOpen and again after
// full workspace/stdlib indexing settles: keep the LAST set per URI.
const diags = new Map();
let buf = Buffer.alloc(0);
server.stdout.on("data", (chunk) => {
  buf = Buffer.concat([buf, chunk]);
  for (;;) {
    const headerEnd = buf.indexOf("\r\n\r\n");
    if (headerEnd < 0) return;
    const m = /Content-Length: (\d+)/.exec(buf.subarray(0, headerEnd).toString());
    const len = Number(m[1]);
    if (buf.length < headerEnd + 4 + len) return;
    const msg = JSON.parse(buf.subarray(headerEnd + 4, headerEnd + 4 + len).toString());
    buf = buf.subarray(headerEnd + 4 + len);
    if (msg.id !== undefined && pending.has(msg.id)) {
      pending.get(msg.id)(msg.result);
      pending.delete(msg.id);
    } else if (msg.method === "textDocument/publishDiagnostics") {
      diags.set(msg.params.uri, msg.params.diagnostics);
    } else if (msg.method === "workspace/configuration") {
      // Langium pulls settings; answer with the stdlib location for every item.
      const settings = msg.params.items.map(() => ({
        standardLibrary: STDLIB !== "",
        standardLibraryPath: STDLIB,
        defaultBuildOptions: { ignoreMetamodelErrors: false },
      }));
      send({ jsonrpc: "2.0", id: msg.id, result: settings });
    } else if (msg.id !== undefined) {
      // unknown server->client request: answer null so the server never stalls
      send({ jsonrpc: "2.0", id: msg.id, result: null });
    }
  }
});

const cwdUri = pathToFileURL(process.cwd()).toString();
await request("initialize", {
  processId: process.pid,
  rootUri: cwdUri,
  workspaceFolders: [{ uri: cwdUri, name: "vxmodels" }],
  capabilities: { workspace: { configuration: true } },
  initializationOptions: {
    syside: { standardLibrary: STDLIB !== "", standardLibraryPath: STDLIB },
  },
});
notify("initialized", {});

for (const f of files) {
  notify("textDocument/didOpen", {
    textDocument: {
      uri: pathToFileURL(resolve(f)).toString(),
      languageId: "sysml",
      version: 1,
      text: readFileSync(f, "utf8"),
    },
  });
}

// Wait for diagnostics to settle: every opened file reported, then quiet period.
const wanted = new Set(files.map((f) => pathToFileURL(resolve(f)).toString()));
const deadline = Date.now() + 120_000;
let lastCount = -1;
let quietSince = Date.now();
for (;;) {
  await new Promise((r) => setTimeout(r, 500));
  const have = [...wanted].filter((u) => diags.has(u)).length;
  const total = [...diags.values()].reduce((n, d) => n + d.length, 0);
  if (have === wanted.size) {
    if (total === lastCount && Date.now() - quietSince > 3000) break;
    if (total !== lastCount) { lastCount = total; quietSince = Date.now(); }
  }
  if (Date.now() > deadline) {
    console.error(`error: timed out; diagnostics received for ${have}/${wanted.size} files`);
    server.kill();
    process.exit(2);
  }
}

let errors = 0;
for (const uri of wanted) {
  const list = diags.get(uri) ?? [];
  const rel = uri.replace(cwdUri + "/", "");
  for (const d of list) {
    const sev = ["", "error", "warning", "info", "hint"][d.severity ?? 1];
    if (d.severity === 1) errors++;
    console.log(`${rel}:${d.range.start.line + 1}:${d.range.start.character + 1}: ${sev}: ${d.message}`);
  }
  if (list.length === 0) console.log(`${rel}: clean`);
}
server.kill();
console.log(errors ? `FAIL: ${errors} error(s)` : "PASS: all files parse and type-check clean");
process.exit(errors ? 1 : 0);
