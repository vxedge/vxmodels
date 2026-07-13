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

- [ ] `models/requirements/` — H1–H4 as `requirement` definitions, one per hypothesis,
      wording lifted verbatim from `docs/ARCHITECTURE.md` §2
- [ ] `verify` links to the frozen archives (manifest digests as the join key):
      exp-001 (`e51721c1a5a0…`, H1), exp-002 (`a8aa539dc04a…`, H3), exp-002b
      (`625840eeeb0c…`, H3 decomposition), exp-003 (`007ffd65472e…`, H4)
- [ ] Record the second-campaign reproducibility checks as verification evidence
      attributes (incl. exp-003's honest absolute-drift caveat)
- [ ] Parse/typing check in CI (textual model must parse clean before merge)

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
- [ ] `sysml-authoring` skill (`.claude/skills/`): how to compose model elements, the
      double gate, what is out of model scope
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
