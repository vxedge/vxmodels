// vxedge track M — M3's pipeline demo: the smallest analysis case that carries
// every field an experiment manifest needs (network/zones/traffic_profiles/
// telemetry/results), so `vxmodel render --experiment` can be built and proven
// end to end without touching a real hypothesis campaign.
//
// This is deliberately NOT exp-010/H2. `exp-010-h2-real-slicing.sysml`'s own
// analysis case only models methodology (CampaignFrame, load levels,
// interference source, the sliceMode variant) — it has no zones, traffic
// profiles, or telemetry in the model at all, because phase1-analysis-cases.sysml
// and exp-010 were both authored to capture the *varied dimension*, not the full
// manifest shape. Re-deriving exp-010.yaml from a grown model would mean
// touching frozen H2 evidence (verdict: HOLDS, docs/STATUS.md) — out of scope
// here by workspace rule. Building a general renderer that also handles that
// methodology-only shape is a separate, larger design question, left open in
// vxmodels/TASKS.md M3 rather than solved by this file.
//
// So: this analysis case is scoped like vx-vehicle-01.sysml was for M2 — a
// small, purpose-built, fully self-contained model, 1:1 with the manifest
// fields it renders. It reuses VxedgeVehicles' *structural* vocabulary
// (VehicleZone, ZoneNode, ZoneRoleKind, the abstract SliceInterface/SlicePort
// base defs) via import rather than duplicating it: an experiment's own
// `zones:` block (§6.1) and a vehicle's `zones:` block (§6.2) are the same
// shape in the manifest schema, so the same SysML constructs model both.
//
// The one thing NOT reused across the import: the concrete slice interface
// (DemoSliceInterface below, vlan/qos values). `vxmodel`'s renderer is a
// narrow, single-file, pattern-based extractor (see vxmodel's own module doc)
// — it doesn't resolve cross-file `private import`s, so a concrete interface
// def has to live in the same file it's rendered from. DemoSliceInterface is
// declared locally here rather than reusing VxedgeVehicles::AdasSliceInterface
// directly, purely for that reason — its vlan/qos values are still copied
// verbatim from vx-vehicle-01.sysml's AdasSliceInterface (itself grounded in
// exp-001.yaml's frozen network.slices[0]), not reinvented.
//
// slicePolicy/services/links/compute are not modeled here, mirroring
// vx-vehicle-01.sysml's own no-overclaiming stance — none of those are
// exercised by this demo.
//
// Not rendered yet — `vxmodel render --experiment` (M3) doesn't exist. Once it
// does, this model is the design authority for
// vxperiments/experiments/exp-pipeline-demo.yaml, gated by
// `vxedge manifest validate --json` before anything here is trusted.

package VxedgePipelineDemo {
	private import ScalarValues::*;
	private import VxedgeVehicles::*;

	// --- locally-declared concrete slice (see file header: not imported) --------

	abstract interface def DemoSliceInterface :> SliceInterface {
		doc /* Values copied verbatim from vx-vehicle-01.sysml's AdasSliceInterface
		     (itself grounded in exp-001.yaml's frozen network.slices[0]) —
		     declared locally rather than reused across files because
		     `vxmodel`'s extractor is single-file/pattern-based, not a real
		     cross-file import resolver. */
		attribute :>> mode = SliceMode::vlan;
		attribute :>> vlan = 101;
		attribute :>> qos {
			attribute :>> minRateMbps = 100;
			attribute :>> maxRateMbps = 200;
			attribute :>> priority = 1;
		}
	}

	port def DemoSlicePort :> SlicePort {
		doc /* Binds to DemoSliceInterface, above. */
	}

	// --- experiment-only vocabulary (no vehicle-model counterpart) ---------------

	attribute def TrafficProfile {
		doc /* One `traffic_profiles` entry (§6.0). source/target name a node
		     *part* in this model, or one of the manifest's symbolic endpoints
		     (`internet`, `carla`) — modeled as plain strings, not a typed
		     reference, since the manifest itself doesn't type them either.
		     Naming the part rather than a rendered device id keeps rendered ids
		     out of the model, which is the sysml-authoring rule; `vxmodel
		     render` resolves the part to whatever device id it emits. Until
		     2026-07-31 this followed §6.1's `<zone>:<node>` convention and named
		     `vxzone-demo-01:node-demo-01`, which the renderer never actually
		     emitted — §6.1 validation does not check traffic endpoints, so a
		     dangling one rendered and validated cleanly for months. §6.0 checks
		     them, and caught it the first time this model was rendered. */
		attribute source : String;
		attribute target : String;
		attribute bandwidthMbps : Natural;
		attribute payloadBytes : Natural;
	}

	attribute def ResultsPolicy {
		doc /* §6.1 `results:` block. */
		attribute artifactDir : String;
		attribute upload : Boolean;
	}

	// --- the analysis case ---------------------------------------------------------

	analysis def PipelineDemoCase {
		doc /* M3 pipeline demo (docs/ARCHITECTURE.md §15 track M, "GenAI generation
		     target"). No H-number, no frozen archive: this case exists solely to
		     exercise the double gate (SysIDE parse/type-check, then
		     `vxmodel render --experiment` + `vxedge manifest validate --json`)
		     end to end, small enough that generating it is a plausible LLM-authoring
		     exercise. One zone, one node, one slice, one traffic profile, one
		     telemetry target — every experiment-manifest section touched once,
		     nothing modeled beyond what's needed to round-trip through both gates. */

		attribute id : String = "exp-pipeline-demo";
		attribute name : String = "vxmodel pipeline demo";
		attribute durationS : Natural = 30;

		part demoZone : VehicleZone {
			attribute :>> role = ZoneRoleKind::frontLeft;
			part demoNode : ZoneNode :>> nodes {
				attribute :>> nodeType = "ecu";
				attribute :>> function = "pipeline demo probe endpoint (vxprobe)";
				port :>> slicePort : DemoSlicePort;
			}
		}

		attribute demoTraffic : TrafficProfile {
			attribute :>> source = "demoNode";
			attribute :>> target = "internet";
			attribute :>> bandwidthMbps = 50;
			attribute :>> payloadBytes = 1200;
		}

		attribute scrapeTarget : String = "127.0.0.1:9801";

		attribute results : ResultsPolicy {
			attribute :>> artifactDir = "results/exp-pipeline-demo";
			attribute :>> upload = false;
		}
	}
}
