// vxedge track M: M2 structure model: vx-vehicle-01, the OEM-representative
// zonal E/E reference vehicle (docs/ARCHITECTURE.md §6.2). Zones/nodes are
// `part` defs, slices+QoS are typed `interface` defs, per the sysml-authoring
// skill's construct mapping table. The `links` harness (the table's third
// row, `connection` usages) is NOT modeled here: no real experiment manifest
// uses the `links:` block yet (grepped vxperiments/experiments/*.yaml,
// 2026-07-19, empty everywhere), so there's no live topology to mirror and
// inventing a star/daisy-chain harness with no grounding would be exactly
// the overclaiming this file's other notes are trying to avoid. Add it once
// a real manifest exercises `links:`.
//
// Grounded, not invented: the two slices modeled here (adas, infotainment)
// and their QoS numbers are copied verbatim from exp-001's live, frozen
// manifest (vxperiments/experiments/exp-001.yaml), the only slice
// configuration this project has actually run and measured. No `services`,
// `signal_plane`, `comms`, or `world` block is modeled yet: those are phase-3
// / stretch schema fields with no built subsystem behind them yet
// (vxota/vxtelemetry ship services already, but binding them into this
// reference vehicle's structure is a separate, later addition once a real
// vx-vehicle-01 experiment needs it; modeling it now would overclaim
// readiness). centralCompute mirrors the manifest's `compute[]` slot only
// structurally: vxcompute has zero code as of 2026-07-19 (docs/RESULTS.md),
// so this is not a claim that Autoware/ROS2/CARLA run today.
//
// This is the design authority; `vxmodel render` (M2, not yet built) turns
// it into vxperiments/vehicles/vx-vehicle-01.yaml, gated by
// `vxedge manifest validate --json` before anything here is trusted.

package VxedgeVehicles {
	private import ScalarValues::*;

	// --- slices as typed interfaces (§6.1 network.slices mirror) ----------------

	enum def SliceMode {
		doc /* §6.1: mode: vlan | s-nssai. Only vlan has a real, measured example
		     so far (exp-001/002/002b/003); s-nssai is exp-010's mode and isn't
		     wired into this reference vehicle yet. */
		vlan;
		sNssai;
	}

	attribute def SliceQos {
		attribute minRateMbps : Natural;
		attribute maxRateMbps : Natural;
		attribute priority : Natural;
	}

	abstract interface def SliceInterface {
		doc /* A network slice a zone node's NIC binds to (§6.1 network.slices,
		     §7 vxgateway VLAN-per-slice data plane). */
		attribute mode : SliceMode;
		attribute vlan : Natural;
		attribute qos : SliceQos;
	}

	abstract interface def AdasSliceInterface :> SliceInterface {
		doc /* adas: URLLC-like, the H1/H2 measured slice. Vlan id + QoS copied
		     verbatim from exp-001.yaml's live network.slices[0] (frozen result
		     reference, results/exp-001). */
		attribute :>> mode = SliceMode::vlan;
		attribute :>> vlan = 101;
		attribute :>> qos {
			attribute :>> minRateMbps = 100;
			attribute :>> maxRateMbps = 200;
			attribute :>> priority = 1;
		}
	}

	abstract interface def InfotainmentSliceInterface :> SliceInterface {
		doc /* infotainment: best-effort load source. Vlan id + QoS copied
		     verbatim from exp-001.yaml's live network.slices[1]. */
		attribute :>> mode = SliceMode::vlan;
		attribute :>> vlan = 103;
		attribute :>> qos {
			attribute :>> minRateMbps = 0;
			attribute :>> maxRateMbps = 400;
			attribute :>> priority = 5;
		}
	}

	// --- zone/node structure (§6.1 zones[].nodes mirror) -------------------------

	enum def ZoneRoleKind {
		doc /* The six recurring logical zone roles (workspace-root CLAUDE.md
		     topology note); this vehicle instantiates the four sensor/actuator
		     zones. gateway and central-hpc are structural, not zone-shaped, in
		     the manifest today (vxgateway is provisioned by `vxedge up`, not a
		     zone; central compute is the separate `compute[]` block below). */
		frontLeft;
		frontRight;
		rearLeft;
		rearRight;
	}

	port def SlicePort {
		doc /* A zone node's network.slice binding point (§6.1 zones[].nodes[].network).
		     Concrete nodes are typed by one of the named subtypes below, not this
		     one directly: the subtype IS the slice binding (`vxmodel render`
		     reads the port's type name to pick `network[].slice`). Named
		     subtypes rather than a binary `interface` connecting to a modeled
		     gateway port: this file doesn't model vxgateway as a part (it's
		     provisioned by `vxedge up`, not a zone; see the ZoneRoleKind doc),
		     so there's no second endpoint to connect to. */
	}

	port def AdasSlicePort :> SlicePort {
		doc /* Binds to AdasSliceInterface (vlan 101, above). */
	}

	port def InfotainmentSlicePort :> SlicePort {
		doc /* Binds to InfotainmentSliceInterface (vlan 103, above). */
	}

	part def ZoneNode {
		doc /* One zone node (§6.1 zones[].nodes[]). */
		attribute nodeType : String;
		attribute function : String;
		port slicePort : SlicePort;
	}

	part def VehicleZone {
		doc /* One zone (§6.1 zones[]). */
		attribute role : ZoneRoleKind;
		part nodes : ZoneNode[1..*];
	}

	// --- central compute (§6.1 compute[] mirror) ---------------------------------

	part def CentralComputeNode {
		doc /* Containerized central compute (§9: Autoware/ROS2, GPU inference).
		     Structural slot only; see the file header note on vxcompute's
		     current state. */
		attribute gpu : String;
	}

	// --- the vehicle itself -------------------------------------------------------

	part def Vehicle {
		doc /* A full software-bootstrapped SDV (§6.2 vehicle: block). Each zone
		     gets its own named slot rather than four parts redefining a shared
		     `zones[1..*]` feature: SysIDE 0.9.1 resolves a single redefinition
		     of a multiplicity feature fine but not multiple sibling
		     redefinitions of the same one (found empirically authoring this
		     file: only the first of four `part … :>> zones` usages resolved,
		     the rest failed with "Could not resolve reference to Feature named
		     'zones'"). Distinct slots side-step the tool limitation and are
		     arguably clearer here anyway, since the four roles aren't
		     interchangeable. */
		attribute id : String;
		attribute vehicleName : String;
		part frontLeftZone : VehicleZone;
		part frontRightZone : VehicleZone;
		part rearLeftZone : VehicleZone;
		part rearRightZone : VehicleZone;
		part centralCompute : CentralComputeNode;
	}

	part vxVehicle01 : Vehicle {
		doc /* vx-vehicle-01: "OEM-representative zonal E/E" (§6.2's own example
		     name). Not yet rendered to vxperiments/vehicles/vx-vehicle-01.yaml:
		     the renderer (`vxmodel`) doesn't exist yet (M2, in progress). */
		attribute :>> id = "vx-vehicle-01";
		attribute :>> vehicleName = "vx-vehicle-01 OEM-representative zonal E/E";

		part :>> frontLeftZone : VehicleZone {
			attribute :>> role = ZoneRoleKind::frontLeft;
			part adasProbeFl : ZoneNode :>> nodes {
				attribute :>> nodeType = "ecu";
				attribute :>> function = "front-left ADAS-representative probe endpoint (vxprobe)";
				port :>> slicePort : AdasSlicePort;
			}
		}

		part :>> frontRightZone : VehicleZone {
			attribute :>> role = ZoneRoleKind::frontRight;
			part adasProbeFr : ZoneNode :>> nodes {
				attribute :>> nodeType = "ecu";
				attribute :>> function = "front-right ADAS-representative probe endpoint (vxprobe)";
				port :>> slicePort : AdasSlicePort;
			}
		}

		part :>> rearLeftZone : VehicleZone {
			attribute :>> role = ZoneRoleKind::rearLeft;
			part infotainmentLoadRl : ZoneNode :>> nodes {
				attribute :>> nodeType = "infotainment";
				attribute :>> function = "infotainment load source (vxtraffic)";
				port :>> slicePort : InfotainmentSlicePort;
			}
		}

		part :>> rearRightZone : VehicleZone {
			doc /* Rear cross-traffic ADAS sensor: rear zones legitimately carry
			     ADAS-relevant sensing too (rear radar/camera), not just
			     infotainment; this is a structural choice, not a measured one;
			     no experiment has exercised this zone yet. */
			attribute :>> role = ZoneRoleKind::rearRight;
			part adasProbeRr : ZoneNode :>> nodes {
				attribute :>> nodeType = "sensor";
				attribute :>> function = "rear cross-traffic ADAS sensor endpoint";
				port :>> slicePort : AdasSlicePort;
			}
		}

		part :>> centralCompute : CentralComputeNode {
			attribute :>> gpu = "passthrough";
		}
	}
}
