# Changelog

All notable changes to this repo are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[Semantic Versioning](https://semver.org/) — see `docs/VERSIONING.md` in the `docs` repo.

## [Unreleased]

### Changed

- **BREAKING: `vxmodel render` emits a §6.0 workspace**, not a §6.1/§6.2 manifest. One file of
  `---`-separated documents — `kind: experiment`, `kind: vehicle`, `kind: baseline` — which a
  workspace is allowed to be, since every §6.0 reference is by id. Both `--vehicle` and
  `--experiment` render and validate clean against the committed models, and CI's
  `pipeline-regression` job asserts `kind == "workspace"` plus workspace counts.

  `vxedge` deleted the retired manifest structs once this landed; rendering them would have
  produced a document shape nothing could run. `--image <vxid>=<url>,<kind>` now decides both a
  device's `backend:` and its part's `kind:`, which is the resolution §6.1 performed implicitly
  from `image.kind`.

### Fixed

- `exp-pipeline-demo.sysml` declared its traffic source as `"vxzone-demo-01:node-demo-01"` — a
  §6.1-shaped id the renderer never actually emitted, so the profile pointed at nothing. §6.1
  does not validate traffic endpoints, so it rendered and validated cleanly for months; §6.0
  caught it on the first render. The model names the node **part** now, and the renderer
  resolves it to the device id it emits, keeping rendered ids out of the model.


### Added
- Headless SysML v2 validation gate (2026-07-13): `scripts/validate-sysml.mjs`
  (dependency-free LSP driver for SysIDE) + CI workflow with digest-pinned toolchain
  (SysIDE 0.9.1, SysML-v2-Release 2026-04 stdlib). Both M1 model files pass; gate
  verified able to fail. Naming rule codified in the sysml-authoring skill:
  `Vxedge` brand token in UpperCamel names, never `VxEdge`.
- M1 retroactive traceability model (2026-07-13): `models/requirements/hypotheses.sysml`
  (H1–H4 verbatim from ARCHITECTURE §2) + `verification.sysml` (per-campaign
  verification defs with digest-keyed evidence attributes, incl. repro checks and the
  exp-003 archive-provenance note). Not yet parser-validated — CI parse gate open
  (`TASKS.md` M1).
- `sysml-authoring` skill (pulled forward from M3): construct mapping, double gate,
  authoring + traceability rules.
- Repo seeded (track M0, 2026-07-13): AGENTS.md (scope + hard rules), TASKS.md (M0–M4
  work items), testbed-quality skill. Spec: `docs/ARCHITECTURE.md` §6.3 + §15 track M.
