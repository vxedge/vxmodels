# Changelog

All notable changes to this repo are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[Semantic Versioning](https://semver.org/). See `docs/VERSIONING.md` in the `docs` repo.

## [Unreleased]

## [0.1.0] - 2026-10-29

First public release.

### Added

- Release workflow: pushing a `v*` tag builds `vxmodel` on native x86_64 and aarch64 Ubuntu 24.04
  runners with `--locked`, packages `vxmodels-<version>-<target>.tar.gz` (the binary, `LICENSE`,
  `NOTICE`), and publishes it with `SHA256SUMS` and build provenance.
- `vxmodel --version` and `vxmodel render --help`.
- `cargo-deny` configuration (`vxmodel/deny.toml`) and a CI job that runs `cargo deny check`.
- `SECURITY.md`, `CITATION.cff`.
- Open-source release preparation: `LICENSE` (Apache-2.0), `LICENSE-DOCS` (CC BY 4.0), `NOTICE`,
  rewritten `README.md`.
- Headless SysML v2 validation gate (2026-07-13): `scripts/validate-sysml.mjs`
  (dependency-free LSP driver for SysIDE) plus a CI workflow with a digest-pinned toolchain
  (SysIDE 0.9.1, SysML-v2-Release 2026-04 stdlib). The gate was verified able to fail. Naming
  rule codified in the sysml-authoring skill: `Vxedge` brand token in UpperCamel names, never
  `VxEdge`.
- M1 retroactive traceability model (2026-07-13): `models/requirements/hypotheses.sysml`
  (H1-H4 verbatim from ARCHITECTURE §2) and `verification.sysml` (per-campaign verification defs
  with digest-keyed evidence attributes, including repro checks and the exp-003
  archive-provenance note).
- `sysml-authoring` skill (pulled forward from M3): construct mapping, double gate, authoring and
  traceability rules.
- Repo seeded (track M0, 2026-07-13): AGENTS.md (scope and hard rules), TASKS.md (M0-M4 work
  items), testbed-quality skill. Spec: `docs/ARCHITECTURE.md` §6.3 and §15 track M.

### Changed

- **BREAKING: `vxmodel render` emits a §6.0 workspace**, not a §6.1/§6.2 manifest. One file of
  `---`-separated documents (`kind: experiment`, `kind: vehicle`, `kind: baseline`), which a
  workspace is allowed to be, since every §6.0 reference is by id. Both `--vehicle` and
  `--experiment` render and validate clean against the committed models, and CI's
  `pipeline-regression` job asserts `kind == "workspace"` plus workspace counts.

  `vxedge` deleted the retired manifest structs once this landed; rendering them would have
  produced a document shape nothing could run. `--image <vxid>=<url>,<kind>` now decides both a
  device's `backend:` and its part's `kind:`, which is the resolution §6.1 performed implicitly
  from `image.kind`.

### Fixed

- `exp-pipeline-demo.sysml` declared its traffic source as `"vxzone-demo-01:node-demo-01"`, a
  §6.1-shaped id the renderer never actually emitted, so the profile pointed at nothing. §6.1
  does not validate traffic endpoints, so it rendered and validated cleanly for months; §6.0
  caught it on the first render. The model names the node **part** now, and the renderer
  resolves it to the device id it emits, keeping rendered ids out of the model.

[Unreleased]: https://github.com/vxedge/vxmodels/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/vxedge/vxmodels/releases/tag/v0.1.0
