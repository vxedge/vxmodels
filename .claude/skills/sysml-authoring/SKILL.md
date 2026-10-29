---
name: sysml-authoring
description: MBSE discipline and SysML v2 authoring rules for vxedge models: use when writing or reviewing any .sysml file here (requirements, vehicle structure, analysis cases, scenarios) or generating experiments from models. Encodes the construct mapping, the double gate, and the single-source rules.
---

# SysML v2 authoring: MBSE rules for vxedge models

Spec: `docs/ARCHITECTURE.md` §6.3 (construct mapping, pipeline) and §4 (single-source
rules). The model is the design authority; manifests remain the sole execution contract.

## Construct mapping (never improvise beyond it)

| You are modeling… | Use | Renders to / links to |
|---|---|---|
| a hypothesis or requirement | `requirement` def + `verify` | frozen result archive (manifest digest is the join key) |
| E/E structure (zones, nodes, harness, slices) | `part` / `connection` / `interface` defs | vehicle manifest (§6.2) |
| an experiment and its arms | `analysis case` + variant points | experiment manifest (§6.1) |
| a traffic/transportation scenario | `use case` / `occurrence` | CARLA scenario (ASAM OpenSCENARIO alignment, M4) |
| a fidelity caveat | metadata annotation on the part | validity envelope in the rendered experiment |

Anything with no row here is out of model scope by rule: Rust internals, the vxAPI IDL,
images/node IDs (zone/compute manifests own those; reference them, never restate them).

## Authoring rules

- **Textual notation only** (`.sysml` files, git-diffable). Graphical views are derived,
  never source.
- **Naming (decided 2026-07-13)**: UpperCamelCase for packages and definitions,
  lowerCamelCase for usages/attributes, and the brand token is `Vxedge`, never
  `VxEdge` (the project name is one lowercase word, `vxedge`; only the grammatical
  first letter is capitalized, no invented internal capitals). Examples:
  `VxedgeHypotheses` (package), `H1Isolation` (def), `h1` / `manifestSha256` (usages).
- **Never name a usage after a SysML v2 keyword.** `frame`, `subject`, `objective`,
  `variant`, `event`, `snapshot`…: the parser fails with a misleading error anchored
  at the *preceding* token (found the hard way: `attribute frame : …` broke the whole
  def body, 2026-07-14). When in doubt, prefix (`campaignFrame`).
- **Enum defs ARE variations.** Their literals are the variants: type the dimension
  attribute by the enum directly (`attribute backend : PackagingBackend;`); wrapping it
  in `variation … { variant … }` is illegal (a variation may not specialize another
  variation). Reserve explicit `variation`/`variant` for non-enum part/config variants.
- **One file, one concern**: `models/requirements/`, `models/vehicles/`,
  `models/experiments/`, `models/scenarios/`. A file that mixes a requirement and a
  structure def gets split.
- **Requirements are verbatim**: hypothesis wording lifts from `ARCHITECTURE.md` §2
  unchanged: the model records, it does not rephrase. Verification evidence (repro
  checks, caveats like exp-003's absolute-drift note) attaches as attributes, honestly.
- **Variant points over copy-paste**: arms (container/libvirt/qemu-microvm, vlan/s-nssai)
  are variation, not duplicated analysis cases. If you copy an analysis case to change
  one value, model a variant point instead.
- **Traceability is bidirectional by digest**: a `verify` link carries the archive's
  manifest sha256; a rendered manifest carries the model digest. Never link by name only.
- **Terminology**: model comments and doc strings say *executable virtual prototype*;
  "digital twin" is reserved until phase-4 hardware parity (`docs/ROADMAP.md`).

## The double gate (non-negotiable, especially for generated models)

1. **Model typing**: the `.sysml` source must parse and type-check clean (SysIDE / pilot
   implementation; CI parse job once it exists).
2. **Manifest validation**: `vxmodel render … && vxedge manifest validate --json <out>`.
   Render failure or validation failure means the model is wrong: fix the model, never
   hand-edit the rendered output.

LLM-generated experiments go through both gates before anything touches the testbed.
There is no third path.

## Verification loop

- Parse/type check on every model edit (editor LSP; CI job per `vxmodels/TASKS.md` M1).
- Render + validate round-trip for anything that renders (M2+).
- Where a hand-written manifest counterpart exists, diff against it and explain every
  difference: silent divergence between model and manifest is a bug in one of them.
- Apply **testbed-quality** to every change here too: reproducibility, fidelity honesty,
  interface stability, standards legibility (OMG SysML v2, ASAM, COVESA VSS).
