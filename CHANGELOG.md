# Changelog

All notable changes to this repo are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[Semantic Versioning](https://semver.org/) — see `docs/VERSIONING.md` in the `docs` repo.

## [Unreleased]

### Added
- M1 retroactive traceability model (2026-07-13): `models/requirements/hypotheses.sysml`
  (H1–H4 verbatim from ARCHITECTURE §2) + `verification.sysml` (per-campaign
  verification defs with digest-keyed evidence attributes, incl. repro checks and the
  exp-003 archive-provenance note). Not yet parser-validated — CI parse gate open
  (`TASKS.md` M1).
- `sysml-authoring` skill (pulled forward from M3): construct mapping, double gate,
  authoring + traceability rules.
- Repo seeded (track M0, 2026-07-13): AGENTS.md (scope + hard rules), TASKS.md (M0–M4
  work items), testbed-quality skill. Spec: `docs/ARCHITECTURE.md` §6.3 + §15 track M.
