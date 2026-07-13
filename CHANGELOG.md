# Changelog

All notable changes to this repo are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[Semantic Versioning](https://semver.org/) — see `docs/VERSIONING.md` in the `docs` repo.

## [Unreleased]

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
