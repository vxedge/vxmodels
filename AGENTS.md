# AGENTS.md — vxedge/vxmodels

SysML v2 system models and the model→manifest renderer for the vxedge platform (track M).
Master spec: `../docs/ARCHITECTURE.md` §6.3 (model governance: construct mapping, pipeline,
GenAI double gate), §4 (single-source rules), §15 track M (M0–M4 roadmap).

## What lands here

- `models/` — `.sysml` textual sources (git-diffable, the authoring format):
  - requirements/traceability model: H1–H4 (then per-experiment) `requirement` definitions
    with `verify` links to frozen result archives in `vxperiments` (manifest digests)
  - vehicle structure models (`part`/`connection`/`interface` defs mirroring §6.2)
  - analysis-case + variant library (experiments and their arms)
  - scenario models (`use case`/`occurrence`; ASAM OpenSCENARIO alignment, M4)
- `vxmodel/` — the renderer (Rust, §15 policy): `vxmodel render` emits YAML manifests
  from models, embedding the model digest.
- `.claude/skills/` — project skills, including the `sysml-authoring` skill (M3).

## Hard rules

- **The model is the design authority; manifests remain the sole execution contract.**
  The daemon/CLI never read models. Every rendered manifest must pass
  `vxedge manifest validate --json` — the render pipeline fails on validation failure.
- **No second source of truth**: the model never duplicates what zone/compute manifests
  are authoritative for (images, node IDs); rendered manifests record the digest of the
  model version that produced them.
- **GenAI double gate** (§6.3): generated experiments clear model typing first, manifest
  validation second, before touching the testbed. Never bypass either gate.
- **Terminology**: vxedge is a *model-governed executable virtual prototype*. "Digital
  twin" is reserved for phase-4 hardware parity (`docs/PUBLICATION.md` terminology rule)
  — never use it in this repo's docs or model comments before then.
- Out of model scope, by rule: Rust internals, the vxAPI IDL (Protobuf stays the
  contract), anything zone/compute manifests own.

## Tooling

Authoring: VS Code + SysIDE (open-source SysML v2 language server) or the OMG SysML v2
pilot implementation (Jupyter) — see `docs/TESTBED-SETUP.md` Tier M for the pinned
versions. Authoring-time only: nothing here runs during a measured experiment.

Headless parse/type gate (CI runs it on every push/PR; run locally before pushing):

```bash
SYSIDE_JS=<path>/syside-languageserver.js \
SYSML_STDLIB=<path>/sysml.library \
node scripts/validate-sysml.mjs models/**/*.sysml
```

## Project skills

AI/contributor skills in `.claude/skills/`: **sysml-authoring** (MBSE discipline: the
construct mapping, the double gate, single-source/traceability rules — apply to every
`.sysml` change) and **testbed-quality** (the OEM-adoption bar — reproducibility,
fidelity honesty, interface stability, standards legibility). **rust-patterns** joins
when the `vxmodel` crate lands (M2).
