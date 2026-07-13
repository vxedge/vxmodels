# TASKS.md — vxedge/vxmodels

Track M work items (cross-cutting; gates nothing in phases 1–4). Program-level view:
`docs/TASKS.md` "Track M"; spec: `docs/ARCHITECTURE.md` §6.3 + §15. Feeds paper #3
(`docs/PUBLICATION.md` §3b).

## M0 — governance & home

- [x] Repo created + seeded (AGENTS.md, TASKS.md, CHANGELOG.md, README.md,
      testbed-quality skill) — 2026-07-13
- [ ] Decide and pin the SysML v2 toolchain versions (SysIDE vs pilot implementation;
      record in `docs/TESTBED-SETUP.md` Tier M once verified)

## M1 — retroactive traceability model (entry increment; zero new experiments)

- [x] `models/requirements/hypotheses.sysml` — H1–H4 as `requirement` definitions,
      wording verbatim from `docs/ARCHITECTURE.md` §2; `h2` carries an explicit
      not-yet-verified doc note (phase-2 gate) instead of a fake link (2026-07-13)
- [x] `models/requirements/verification.sysml` — verification defs `verify`-linked to
      the archives, full 64-char digests where recoverable: exp-001
      (`e51721c1a5a0…`, H1), exp-002 (`a8aa539dc04a…`, H3, post-retrofit), exp-002b
      (`625840eeeb0c…`, H3 decomposition), exp-003 rerun (`5dc4c2a6b860…`, H4).
      Provenance recorded honestly: exp-003's *original* campaign digest survives only
      truncated (`007ffd65472e…`) — its archives were overwritten in place by the
      rerun; exp-002's pre-retrofit digest was superseded by design (2026-07-13)
- [x] Second-campaign reproducibility checks recorded as `reproCheck` evidence
      attributes, incl. exp-003's absolute-drift caveat (2026-07-13)
- [ ] Parse/typing check in CI (textual model must parse clean before merge) — also
      blocks the local double gate: no SysML v2 toolchain installed on the dev host
      yet (see M0 toolchain-pinning item); the .sysml files above are authored to the
      standard textual notation but have NOT yet passed a parser

## M2 — structure model + renderer

- [ ] `models/vehicles/vx-vehicle-01.sysml` — zones/nodes as `part` defs, `links`
      harness as `connection`s, slices+QoS as typed `interface`s (§6.2 mirror)
- [ ] `vxmodel` crate (Rust): `vxmodel render --vehicle <model> --out <manifest.yaml>`,
      embedding the model digest; fails if `vxedge manifest validate --json` rejects
- [ ] Round-trip check in CI: render → validate → diff against the hand-written
      vx-vehicle-01 manifest once it exists in `vxperiments`
- [ ] Add rust-patterns skill + standard Rust CI (build/test/clippy/fmt) when the crate
      lands

## M3 — analysis cases + variants (GenAI generation target; aligns with phase 2)

- [ ] `models/experiments/` — exp-001/002/002b/003 retro-modeled as `analysis case`s
      (calibration set), then new experiments authored model-first
- [ ] Variant points for arms: packaging (container/libvirt/qemu-microvm), slice mode
      (vlan/s-nssai) — mechanical arm enumeration
- [x] `sysml-authoring` skill (`.claude/skills/`): construct mapping, double gate,
      out-of-scope rules — delivered early with the M0 seed (2026-07-13)
- [ ] First LLM-generated experiment passes both gates and runs end-to-end (documented
      as the paper-#3 pipeline demo)

## M4 — scenarios + fidelity ledger (aligns with phases 2–3)

- [ ] Scenario models (`use case`/`occurrence`) for CARLA traffic/transportation
      scenarios; mapping table toward ASAM OpenSCENARIO
- [ ] Fidelity ledger: per-part caveat annotations (shared-host gateway, QNX-as-guest,
      non-PREEMPT_RT, userspace timestamps) → rendered per-experiment validity envelope
- [ ] Environmental KPIs as verified requirements (energy per slice/workload via
      vxtelemetry's DCGM/NVML hooks)
- [ ] V2X multi-vehicle scenario families (phase 3: second vehicle instance + `rsu`)
