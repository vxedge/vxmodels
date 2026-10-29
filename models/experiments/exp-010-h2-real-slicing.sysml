// vxedge track M: M3's first MODEL-FIRST analysis case (not retroactive, unlike
// the phase-1 calibration set in phase1-analysis-cases.sysml, which retro-models
// campaigns that had already run). H2 (real S-NSSAI slicing vs static VLAN mapping);
// this model is authored *before* exp-010 runs, per M3's own stated plan ("New
// experiments authored model-first: starts with exp-010/H2").
//
// Honest process gap, recorded here rather than hidden: the sysml-authoring skill's
// double gate calls for `vxmodel render … && vxedge manifest validate --json <out>`
// as gate 2. `vxmodel` does not exist yet (M2 not started: no crate, blocked on
// vehicle-manifest structs landing in vxedge-core) and would be scoped to vehicle
// manifests (`--vehicle` flag) even once it exists, not experiment manifests. Until
// an experiment-manifest renderer is scoped and built, `exp-010.yaml` is hand-derived
// from this model as a documented stopgap, diffed field-by-field against it
// (sysml-authoring skill's verification-loop rule: "where a hand-written manifest
// counterpart exists, diff against it and explain every difference"), and owed
// re-derivation via a real renderer once one lands. Gate 1 below (parse/type-check)
// is real, run against the pinned toolchain; gate 2 ran what actually exists today
// (`vxedge manifest validate --json`), not the full render+validate pipeline the
// skill specifies for a fully-tooled pipeline.

package VxedgePhase2Experiments {
	private import ScalarValues::*;
	private import VxedgePhase1Experiments::*;

	enum def SliceMode {
		doc /* How network.slices are provisioned: the H2 experimental variable.
		     Mirrors vxedge-core::manifest::SliceMode's own two variants exactly. */
		vlan;
		snssai;
	}

	analysis def Exp010RealSlicingComparison {
		doc /* H2: identical topology and probe methodology to exp-001 (adas p99 RTT
		     under stepped infotainment overload), slice-provisioning mechanism
		     varied instead of held fixed. The vlan arm reproduces exp-001's own
		     mechanism exactly, so it is directly comparable to exp-001's frozen
		     numbers without a separate same-day baseline campaign; the snssai arm
		     provisions the identical topology over real Open5GS+UERANSIM S-NSSAI
		     PDU sessions (vxedge-core::fiveg, live-verified end to end 2026-07-17:
		     CN/RAN pod split, one pod/netns per UE, GatewayService wiring, real
		     vxbr0 bridging, 0% loss both slices) instead of VLAN/HTB. H2 holds if
		     the snssai arm's isolation is at least as good as, and, under
		     contention, measurably better than, the vlan arm's (ARCHITECTURE.md
		     §2 hypothesis wording, §12 analysis plan: "static VLAN mapping vs
		     real S-NSSAI slicing"). */
		attribute campaignFrame : CampaignFrame {
			attribute :>> repetitions = 5;
			attribute :>> warmupS = 10;
			attribute :>> probeWindowS = 60;
			attribute :>> probePps = 1000;
			attribute :>> isolation = "single-arm";
		}
		attribute loadLevelsMbps : Natural[1..*] = (0, 100, 250, 400, 600);
		attribute interference : InterferenceSource = InterferenceSource::infotainmentTraffic;
		attribute sliceMode : SliceMode {
			doc /* Varied dimension: vlan (== exp-001's own mechanism, giving a
			     same-day comparison baseline alongside the frozen exp-001
			     archive) vs snssai (the H2 mechanism under test). Two arms. */
		}
	}
}
