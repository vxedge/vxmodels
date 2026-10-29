# AGENTS.md: vxedge/vxmodels

SysML v2 system models and the model→manifest renderer for the vxedge platform (track M).
Master spec: `../docs/ARCHITECTURE.md` §6.3 (model governance: construct mapping, pipeline,
GenAI double gate), §4 (single-source rules), §15 track M (M0–M4 roadmap).

## What lands here

- `models/`: `.sysml` textual sources (git-diffable, the authoring format):
  - requirements/traceability model: H1–H4 (then per-experiment) `requirement` definitions
    with `verify` links to frozen result archives in `vxperiments` (manifest digests)
  - vehicle structure models (`part`/`connection`/`interface` defs; rendered into the
    `kind: vehicle` and device documents of a §6.0 workspace)
  - analysis-case + variant library (experiments and their arms)
  - scenario models (`use case`/`occurrence`; ASAM OpenSCENARIO alignment, M4)
- `vxmodel/`: the renderer (Rust, §15 policy). `vxmodel render` emits a §6.0 workspace
  (YAML) from a model, embedding the model digest.
- `.claude/skills/`: project skills, including the `sysml-authoring` skill (M3).

## Hard rules

- **The model is the design authority; manifests remain the sole execution contract.**
  The daemon/CLI never read models. Every rendered manifest must pass
  `vxedge manifest validate --json`; the render pipeline fails on validation failure.
- **No second source of truth**: the model never duplicates what zone/compute manifests
  are authoritative for (images, node IDs); rendered manifests record the digest of the
  model version that produced them.
- **GenAI double gate** (§6.3): generated experiments clear model typing first, manifest
  validation second, before touching the testbed. Never bypass either gate.
- **Terminology**: vxedge is a *model-governed executable virtual prototype*. "Digital
  twin" is reserved for phase-4 hardware parity (`docs/ROADMAP.md` terminology rule):
  never use it in this repo's docs or model comments before then.
- Out of model scope, by rule: Rust internals, the vxAPI IDL (Protobuf stays the
  contract), anything zone/compute manifests own.

## Tooling

Authoring: VS Code + SysIDE (open-source SysML v2 language server) or the OMG SysML v2
pilot implementation (Jupyter): see `docs/TESTBED-SETUP.md` Tier M for the pinned
versions. Authoring-time only: nothing here runs during a measured experiment.

Headless parse/type gate (CI runs it on every push/PR; run locally before pushing):

```bash
SYSIDE_JS=<path>/syside-languageserver.js \
SYSML_STDLIB=<path>/sysml.library \
node scripts/validate-sysml.mjs models/**/*.sysml
```

`vxmodel/` (Rust, landed 2026-07-19; `--experiment` added 2026-07-19 for M3): `vxmodel
render (--vehicle | --experiment) <model.sysml> --out <workspace.yaml> --image
<vxid>=<url>,<kind> [...]`, whose output feeds gate 2 of the double gate
(`vxedge manifest validate --json`). Both modes emit one **§6.0 workspace** file:
`---`-separated `kind: experiment`, `kind: vehicle` and `kind: baseline` documents
(the §6.1/§6.2 manifests were retired on 2026-07-31; `vxedge` no longer reads them).
`--vehicle` renders a vehicle structure model (M2). `--experiment` renders a fully
self-contained analysis case (M3: every workspace section modeled 1:1, like
`exp-pipeline-demo.sysml`), not the methodology-only analysis cases in
`phase1-analysis-cases.sysml`/`exp-010-h2-real-slicing.sysml`, which have no devices,
slices or traffic in the model to render from. `--image` sets both a device's `backend:`
and its part's `kind:`. Rendered files are validated, not yet run: the renderer emits no
`.vxp`, so `vxedge experiment up` cannot address them (deferred to phase 3, `TASKS.md`).
Not a general SysML v2 parser: a narrow, single-file, pattern-based extractor scoped to this repo's own
`sysml-authoring`-enforced conventions (see the crate's module doc); notably, it doesn't
resolve cross-file `private import`s, so a concrete (value-bearing) interface def has to
live in the same file it's rendered from; purely structural defs are fine to import.
Images are a required, explicit CLI input, never invented; the model doesn't carry them
by rule (§ below), and no real `vxparts` image exists yet for these nodes.
`cd vxmodel && cargo build --locked / test / clippy --all-targets -- -D warnings / fmt --check
/ deny check` (own `Cargo.lock`, `deny.toml` and `rust-toolchain.toml`, pinned 1.96.1 to match
`vxedge`'s). Releases: pushing a `vX.Y.Z` tag runs `.github/workflows/release.yml`, which
publishes `vxmodels-<ver>-<target>.tar.gz` for x86_64 and aarch64 Linux with `SHA256SUMS` and
build provenance; the tag must match the crate version.

## Project skills

AI/contributor skills in `.claude/skills/`: **sysml-authoring** (MBSE discipline: the
construct mapping, the double gate, single-source/traceability rules; apply to every
`.sysml` change) and **testbed-quality** (the OEM-adoption bar: reproducibility,
fidelity honesty, interface stability, standards legibility). **rust-patterns** applies
to `vxmodel/` now that the crate has landed (M2, 2026-07-19).
