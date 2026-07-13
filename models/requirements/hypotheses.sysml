// vxedge track M — M1 retroactive traceability model (requirements half).
// Requirement wording is VERBATIM from docs/ARCHITECTURE.md §2 — the model records,
// it does not rephrase (sysml-authoring skill rule). Verification evidence lives in
// verification.sysml; the join key between model and evidence is the experiment
// manifest sha256, never a name.
//
// Terminology: this models an *executable virtual prototype*. The term "digital twin"
// is reserved until phase-4 hardware parity (docs/PUBLICATION.md terminology rule).

package VxedgeHypotheses {

	requirement def H1Isolation {
		doc /* H1 (isolation): Per-slice VLAN/VXLAN mapping with hierarchical tc
		     queue-tree reservations in vxgateway can keep p95/p99 latency for ADAS
		     (URLLC-like) traffic near baseline under heavy infotainment load. */
	}

	requirement def H2RealSlicing {
		doc /* H2 (real slicing vs. static mapping): True 5G slicing (S-NSSAI PDU
		     sessions via Open5GS + UERANSIM) provides measurably different — and
		     under contention, stronger — isolation than static VLAN-to-slice
		     mapping. */
	}

	requirement def H3VirtualizationChoice {
		doc /* H3 (virtualization choice): Virtual ECU packaging (full VM via libvirt
		     vs. container vs. microVM via raw QEMU/QMP or cloud-hypervisor) measurably
		     affects latency/jitter observable at zone-to-compute flows. */
	}

	requirement def H4ServiceCoLocation {
		doc /* H4 (service co-location): OTA service co-located in central compute
		     (deployed on demand) does not compromise ADAS slice SLAs when slices and
		     queue reservations are correctly configured. */
	}

	requirement h1 : H1Isolation;

	requirement h2 : H2RealSlicing {
		doc /* Not yet verified — phase-2 gate (paper #2 dataset). The absence of a
		     verify link here is the honest state of the traceability chain, not an
		     omission: no verification case exists until the Open5GS/UERANSIM driver
		     lands and exp-010 (or successor) runs. */
	}

	requirement h3 : H3VirtualizationChoice;

	requirement h4 : H4ServiceCoLocation;
}
