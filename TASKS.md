# TASKS.md — vxedge/vxmodels

Track M work items (cross-cutting; gates nothing in phases 1–4). Program-level view:
`docs/TASKS.md` "Track M"; spec: `docs/ARCHITECTURE.md` §6.3 + §15. Feeds paper #3
(`docs/PUBLICATION.md` §3b).

## M0 — governance & home

- [x] Repo created + seeded (AGENTS.md, TASKS.md, CHANGELOG.md, README.md,
      testbed-quality skill) — 2026-07-13
- [x] Toolchain pinned (2026-07-13): **SysIDE 0.9.1** (`syside-languageserver.zip`,
      sha256 `1c3da428…`) as the parse/type gate + **SysML-v2-Release 2026-04**
      `sysml.library` (sha256 `44996ee2…`) as the standard library — both verified by
      digest in CI (`.github/workflows/ci.yml`). SysIDE is LSP-only, so
      `scripts/validate-sysml.mjs` (dependency-free Node LSP driver) provides the
      headless one-shot gate. The OMG pilot implementation stays the semantic
      reference for anything SysIDE and the spec disagree on. Recorded in
      `docs/TESTBED-SETUP.md` Tier M

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
- [x] Parse/typing check in CI (2026-07-13): `.github/workflows/ci.yml` runs
      `scripts/validate-sysml.mjs` (SysIDE over LSP stdio, stdlib linked) on every
      `models/**/*.sysml`. Both M1 files **PASS** parse + type-check; gate proven
      able to fail (negative test: syntax error + two unresolved references all
      caught, exit 1)

## M2 — structure model + renderer

**Blocked on `vxedge`:** vehicle-manifest structs (§6.2) are still TODO in vxedge-core
(`vxedge/TASKS.md` §1), so `vxedge manifest validate` cannot validate a rendered vehicle
manifest — the M2 gate can't run until that phase-1 carryover lands. Structure-model
authoring can start anytime; the renderer waits.

- [ ] `models/vehicles/vx-vehicle-01.sysml` — zones/nodes as `part` defs, `links`
      harness as `connection`s, slices+QoS as typed `interface`s (§6.2 mirror)
- [ ] `vxmodel` crate (Rust): `vxmodel render --vehicle <model> --out <manifest.yaml>`,
      embedding the model digest; fails if `vxedge manifest validate --json` rejects
      *(gate blocked: needs vehicle-manifest structs in vxedge-core first)*
- [ ] Round-trip check in CI: render → validate → diff against the hand-written
      vx-vehicle-01 manifest once it exists in `vxperiments`
- [ ] Add rust-patterns skill + standard Rust CI (build/test/clippy/fmt) when the crate
      lands

## M3 — analysis cases + variants (GenAI generation target; aligns with phase 2)

- [x] `models/experiments/phase1-analysis-cases.sysml` (2026-07-14) — exp-001/002/002b/
      003 retro-modeled as `analysis def`s (calibration set): enumerated dimensions
      (PackagingBackend/VirtioTransport/QemuMachine/InterferenceSource), shared
      CampaignFrame, per-campaign varied-vs-fixed structure. Passes the SysIDE gate.
      Two grammar lessons codified in sysml-authoring: keyword collisions (`frame`),
      enum-defs-are-variations
- [x] New experiments authored model-first — **delivered 2026-07-17,
      `models/experiments/exp-010-h2-real-slicing.sysml`**: the first
      analysis case modeled *before* it runs (phase1-analysis-cases.sysml's
      four are retro-modeled; this is the actual forward flow M3 was scoped
      for). `Exp010RealSlicingComparison` reuses `VxedgePhase1Experiments`'s
      `CampaignFrame`/`InterferenceSource` unchanged (identical methodology
      to exp-001) with a new `SliceMode` enum (`vlan`/`snssai`) as the H2
      variant dimension. Passes the SysIDE gate clean, no regression to the
      existing models. Honest process gap recorded in the file itself: `
      vxmodel` (M2) doesn't exist yet, so `exp-010.yaml` will need to be
      hand-derived from this model rather than rendered — gate 2 of the
      double gate runs partially (real `vxedge manifest validate --json`,
      no automated render) until M2 lands.
- [x] Slice-mode dimension (vlan/s-nssai) joined the calibration set —
      `SliceMode` enum in `exp-010-h2-real-slicing.sysml` (see above)
- [x] `sysml-authoring` skill (`.claude/skills/`): construct mapping, double gate,
      out-of-scope rules — delivered early with the M0 seed (2026-07-13)
- [x] Model-first flow closed the loop — **`exp-010-h2-real-slicing.sysml`'s
      `Exp010RealSlicingComparison` now has a real verification record, and
      H2's real, final verdict is HOLDS** (2026-07-18):
      `models/requirements/verification.sysml`'s `Exp010RealSlicingVerification`
      (`objective { verify h2; }`) carries the full three-campaign
      trajectory, not just the answer — `campaign` (pre-fix, DOES NOT HOLD,
      root cause identified: `fiveg` rendered no per-slice QoS anywhere),
      `htbFixRetest` (real HTB fix landed and verified live, but still
      formally borderline — 1.03x vs a 1.023x threshold — on an unmitigated
      host), `finalRetest` (cpu governor pinning + cpu affinity +
      randomized load order closed the gap: adas p99 growth
      baseline→600mbit is 1.00x snssai vs 0.93x vlan — **H2 HOLDS**). All
      three joined to their real campaigns by manifest sha256, per the
      model's own single-source-of-truth rule. `hypotheses.sysml`'s `h2`
      doc comment updated to the final result, narrating the trajectory
      rather than just the destination. Both files reverified clean
      against the pinned SysIDE toolchain after every edit. Full account:
      `docs/STATUS.md`, `vxedge/TASKS.md`, `vxperiments/TASKS.md`
- [ ] First LLM-generated experiment passes both gates and runs end-to-end (documented
      as the paper-#3 pipeline demo)

## M4 — scenarios + fidelity ledger (aligns with phases 2–3)

**Blocked on `vxcompute`:** scenario models need CARLA actually wired (phase-2 board,
first code in that repo) before there is anything real to model against; fidelity-ledger
annotations can start once M2's structure model exists.

- [ ] Scenario models (`use case`/`occurrence`) for CARLA traffic/transportation
      scenarios; mapping table toward ASAM OpenSCENARIO
- [ ] Fidelity ledger: per-part caveat annotations (shared-host gateway, QNX-as-guest,
      non-PREEMPT_RT, userspace timestamps) → rendered per-experiment validity envelope.
      Candidate annotation input, gated two-deep (Alpamayo landing in `vxcompute` phase 3,
      *and* this item unblocking — not near-term actionable): the ASIMOV dataset
      (https://asimov-benchmark.github.io/v1/, semantic-safety eval for foundation-model
      AV controllers) as a semantic-safety fidelity annotation for Alpamayo specifically,
      alongside this ledger's existing network/host caveats — everything else the ledger
      tracks is network/timing fidelity, never model semantic safety, and Alpamayo is the
      one workload that question actually applies to. Mirrored in `vxcompute/TASKS.md`
      phase 3's Alpamayo item
- [ ] Environmental KPIs as verified requirements (energy per slice/workload via
      vxtelemetry's DCGM/NVML hooks)
- [ ] V2X multi-vehicle scenario families (phase 3: second vehicle instance + `rsu`)
