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
		doc /* Verified 2026-07-18 (exp-010, snssai arm; vlan arm = exp-001's own
		     frozen numbers) — DOES NOT HOLD as stated, with a code-verified root
		     cause, not just an observation: vxedge-core::fiveg does not yet render
		     any per-slice QoS (5QI/ARP/AMBR all hardcoded identical across every
		     subscriber/slice), so the snssai arm's two PDU sessions compete
		     undifferentiated for the same gNB/UPF path while the vlan arm's
		     isolation comes from real HTB priority+rate enforcement — an unequal
		     comparison, not evidence the hypothesis is false. See
		     verification.sysml's Exp010RealSlicingVerification for the full
		     evidence record and vxedge/TASKS.md for the QoS-differentiation gap
		     this surfaced. */
	}

	requirement h3 : H3VirtualizationChoice;

	requirement h4 : H4ServiceCoLocation;
}
