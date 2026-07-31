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

**Delivered 2026-07-19, both gates live-verified end to end.** Unblocked the same day by
vehicle-manifest structs (§6.2) landing in vxedge-core (`VehicleManifest` + shared
`validate_composition()`; `vxedge/TASKS.md` §1) — `vxedge manifest validate` now
validates vehicle manifests directly (sniffs the top-level `vehicle:` key, no new flag).

- [x] `models/vehicles/vx-vehicle-01.sysml` — zones/nodes as `part` defs, slices+QoS as
      typed `interface` defs (§6.2 mirror). Grounded, not invented: the two slices
      (adas/infotainment) and their QoS are copied verbatim from exp-001's live, frozen
      manifest — the only slice config this project has actually measured. `links` harness
      (the construct table's third row, `connection` usages) is deliberately NOT modeled:
      no real experiment manifest uses `links:` yet, so there's no live topology to mirror.
      `services`/`signal_plane`/`comms`/`world` are also not modeled — phase-3/stretch
      schema fields with no built subsystem behind them (vxcompute has zero code); adding
      them now would overclaim readiness. `centralCompute` mirrors the manifest's
      `compute[]` slot structurally only, same reason. Passes the SysIDE gate (gate 1).
      One real SysIDE 0.9.1 tool limitation found and worked around, documented in the
      model's own `Vehicle` doc comment: four sibling `part` usages redefining the same
      shared multiplicity feature (`zones[1..*]`) fail to resolve past the first one —
      worked around with four distinctly-named feature slots instead of one shared one.
- [x] `vxmodel` crate (Rust, `vxmodels/vxmodel/`): `vxmodel render --vehicle <model> --out
      <manifest.yaml> --image <vxid>=<url>,<kind> [...]`. NOT a general SysML v2 parser —
      a narrow, pattern-based extractor scoped to exactly this repo's own
      `sysml-authoring`-enforced conventions (fixed `attribute :>> name = value;`
      redefinition shape); documented as a real, stated limitation in the crate's module
      doc. Two schema/design decisions made explicit rather than silently baked in:
      (1) **images are a required, explicit CLI input, never invented** — the
      sysml-authoring skill rules images out of model scope, and no real vxzones/vxcompute
      image exists yet for this vehicle's nodes, so the renderer refuses to fabricate
      plausible-looking URLs and fails loudly listing exactly which vxids are missing one
      (live-verified: partial `--image` set → exit 1, no file written, listing the rest);
      (2) **the model digest (§6.3) is recorded as a `# model-digest: sha256:...` YAML
      comment header, not a manifest field** — `VehicleManifest` has
      `#[serde(deny_unknown_fields)]` and no digest field, and adding one is a manifest-
      shape change that needs ARCHITECTURE.md §6.2 sign-off first (workspace CLAUDE.md
      hard rule) — **flagged here as an open, undecided schema question**, not decided
      unilaterally. 3 unit tests (real-model extraction, YAML shape, a malformed-model
      error path), clippy/fmt clean. **Both gates live-verified end to end**: `vxmodel
      render` on the real `vx-vehicle-01.sysml` → `vxedge manifest validate --json` on the
      output → `{"valid":true,"kind":"vehicle","vehicle_id":"vx-vehicle-01","zones":4,
      "compute":1}`.
- [x] Round-trip check in CI: render → validate. **Gate 2 wired 2026-07-19** (regression-
      suite scoping, user request): `.github/workflows/ci.yml`'s new `pipeline-regression`
      job checks out `vxedge` as a sibling repo, builds `vxedge-cli`, then runs the full
      double-gate pipeline (SysIDE already gated by the `validate-models` job; render →
      `vxedge manifest validate --json`) for both renderable models — `vx-vehicle-01.sysml`
      (M2, asserts `valid, zones==4, compute==1`) and `exp-pipeline-demo.sysml` (M3, asserts
      `valid, zones==1, kind==experiment`) — script logic verified locally (identical
      commands, identical output) before committing. Requires a repo secret
      `VXEDGE_CROSS_REPO_TOKEN` (PAT with read access to `vxedge/vxedge`, since both repos
      are private) — provisioned 2026-07-20; two real issues found and fixed by actually
      running the job rather than assuming it worked: (1) the fine-grained PAT had
      Metadata + security-advisories permissions set but no `Contents` permission, so
      checkout 403'd with a misleading "Write access ... not granted" message even though
      it's a pure read — fixed by adding `Contents: Read-only`; (2) `vxedge-cli`'s build
      failed with `protoc` missing (`vxedge-api`'s `tonic-prost-build` needs it, and this
      job's runner is fresh, unlike `vxedge`'s own CI which already installs it) — fixed by
      adding the same `apt-get install protobuf-compiler` step `vxedge`'s CI uses. **Live
      in CI now**: run 29745370581, all three jobs green, including the two `jq` assertions
      inside `pipeline-regression` (`valid`/`zones==4`/`compute==1` for the vehicle path,
      `valid`/`zones==1`/`kind==experiment` for the experiment path). The diff-against-
      hand-written third leg still has nothing to diff against:
      no `vx-vehicle-01.yaml`/`exp-pipeline-demo.yaml` exists in `vxperiments` (nobody's
      asked for one outside these models) — left open, not solved by this job.
- [x] Add rust-patterns skill + standard Rust CI (build/test/clippy/fmt) — done 2026-07-19
      (`AGENTS.md` project-skills note, `.github/workflows/ci.yml`'s `rust` job).

## Renderer emits §6.0 workspaces — **delivered 2026-07-31**

`vxedge` retired §6.1/§6.2 and deleted their structs. This repo moved first so no gate was ever
red: `vxmodel render` emits workspaces, CI asserts the new shape, and only then did `vxedge`
delete `manifest.rs`.

- [x] **`vxmodel render` emits a §6.0 workspace** — one file, `---`-separated: `kind:
      experiment` + `kind: vehicle` + `kind: baseline`. A workspace is allowed to be one file
      because every §6.0 reference is by id, so the renderer still writes a single artifact.
      Both paths (`--vehicle`, `--experiment`) render and validate clean against the real
      models. Placement rather than invention: slices are experiment-level in §6.0, zones become
      regions with one device each, `--image <vxid>=<url>,<kind>` decides both the device's
      `backend:` and the part's `kind:` (the resolution §6.1 did implicitly from `image.kind`),
      and a node's `function`/`nodeType` prose — which §6.0 has no field for — is kept as a
      comment rather than dropped.
- [x] **`pipeline-regression` updated** — asserts `kind == "workspace"` plus workspace counts
      (`devices`, `slices`, `vehicles`, `experiment_id`). Pinning `kind` matters: without it the
      job would have passed on a renderer that regressed, back when validate still accepted the
      old shapes. Both gates were run locally with the exact CI assertions before committing.
- [x] **`vxedge` deleted `manifest.rs`** once this landed.

**A real defect this surfaced.** `exp-pipeline-demo.sysml` declared its traffic source as
`"vxzone-demo-01:node-demo-01"` — §6.1's synthesized `<zone>:<node>` form, naming a node the
renderer never actually emitted. §6.1 does not validate traffic endpoints at all, so it rendered
and validated cleanly for months. §6.0 checks them and caught it on the first render. The model
now names the node **part** (`demoNode`) and the renderer resolves it to whatever device id it
emits, which also keeps rendered ids out of the model as the sysml-authoring skill requires.

**Still open: where the model digest lives.** It is a `# model-digest:` comment because no
document had a field for it. A §6.0 workspace has a `.vxp` descriptor, which is the natural
home — but adding a field there is an `ARCHITECTURE.md` §6.0 change needing the same sign-off
any schema change does.

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
- [x] First LLM-generated experiment passes both gates and runs end-to-end — **delivered
      2026-07-19, both gates live-verified end to end**:
      `models/experiments/exp-pipeline-demo.sysml` (new `PipelineDemoCase` analysis def) +
      `vxmodel render --experiment` (extends the M2 crate, doesn't replace it). Scoped
      deliberately narrow, per an explicit design check-in before building
      (`vxmodels/TASKS.md`'s own M3 line was left open for exactly this reason): this is
      **not** exp-010/H2 re-derived. `exp-010-h2-real-slicing.sysml`'s analysis case only
      models methodology (CampaignFrame, load levels, interference source, the sliceMode
      variant) — no zones/traffic_profiles/telemetry in the model at all — so nothing to
      render a manifest from without growing that model or reopening frozen H2 evidence
      (verdict: HOLDS), both ruled out. Instead: one small, purpose-built, fully
      self-contained analysis case (every §6.1 section touched once — network, zones,
      traffic_profiles, telemetry, results), same "1:1 with the manifest" scoping vx-
      vehicle-01.sysml used for M2. Reuses `VxedgeVehicles`' *structural* vocabulary
      (`VehicleZone`/`ZoneNode`/`ZoneRoleKind`/the abstract `SliceInterface`/`SlicePort`)
      via `private import`; the one concrete (value-bearing) interface, `DemoSliceInterface`,
      is declared locally rather than imported — real tool-scope reason recorded in both the
      model's header and `vxmodel`'s module doc: the extractor is single-file/pattern-based,
      it doesn't resolve cross-file imports, so a concrete interface has to live in the file
      it's rendered from (values still copied verbatim from vx-vehicle-01's own
      `AdasSliceInterface`, not reinvented). Naming, approved before implementation per the
      user's explicit request: no `*Manifest` suffix anywhere — `extract::AnalysisCase`
      (named after the SysML construct it reads, mirroring M2's `extract::VehicleModel`,
      and deliberately distinct from `vxedge_core::ExperimentManifest`'s name), CLI
      `--experiment <model.sysml>` alongside the existing `--vehicle` (mutually exclusive,
      shared `--out`/`--image`). 3 new unit tests (real-model extraction, YAML shape, a
      malformed-model error path — 6 total in the crate now), clippy/fmt clean. **Both gates
      live-verified end to end**: SysIDE gate (incl. a negative test: broken port reference
      → caught, restored → clean) → `vxmodel render --experiment` on the real model →
      `vxedge manifest validate --json` on the output →
      `{"valid":true,"kind":"experiment","experiment_id":"exp-pipeline-demo","zones":1,
      "compute":0,"services":0}`. Failure path also verified: no `--image` → exit 1, no file
      written; `--vehicle` + `--experiment` together → rejected as mutually exclusive.
      **Left open, not solved here** (flagged rather than silently decided): rendering the
      methodology-only analysis-case shape (exp-010's own), and how an open variant
      dimension (e.g. `sliceMode` with no default) collapses to one concrete manifest —
      both need their own design pass if/when a real hypothesis campaign needs generating
      this way, not assumed solved by this demo. Regression test suite planned as the next
      item after this (user request, not yet scoped).

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
