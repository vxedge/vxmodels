// vxedge track M — M1 retroactive traceability model (requirements half).
// Requirement wording is VERBATIM from docs/ARCHITECTURE.md §2 — the model records,
// it does not rephrase (sysml-authoring skill rule). Verification evidence lives in
// verification.sysml; the join key between model and evidence is the experiment
// manifest sha256, never a name.
//
// Terminology: this models an *executable virtual prototype*. The hardware-parity
// term is reserved until phase 4 (docs/ROADMAP.md terminology rule).

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
		doc /* HOLDS — final verdict 2026-07-18 (exp-010, snssai arm; vlan arm =
		     exp-001's own frozen numbers). Real, kernel-level per-slice isolation
		     (gateway::provision::apply_fiveg_slice_qos, an HTB tree on the
		     host-side fiveg uplink mirroring the vlan arm's own apply_slices
		     mechanism) delivers adas p99 growth of 1.00x baseline->600mbit vs the
		     vlan arm's own 0.93x — comfortably inside tolerance. Not the first
		     verdict this hypothesis got the same day: an earlier same-day campaign
		     found DOES NOT HOLD with a code-verified root cause (fiveg rendered no
		     per-slice QoS at all — an unequal comparison, not evidence against the
		     hypothesis); the fix that closed that gap was itself checked
		     empirically before trusting it (Open5GS's own subscriber AMBR field
		     was confirmed live to be recorded but not enforced, so the fix is
		     kernel HTB, not 5G-core config); and the first HTB-fix rerun was still
		     formally borderline until host measurement confounds (cpu governor,
		     cpu affinity, fixed load-order sequence) were closed too. See
		     verification.sysml's Exp010RealSlicingVerification (`campaign` ->
		     `htbFixRetest` -> `finalRetest`) for the complete trajectory, not just
		     the final answer. */
	}

	requirement h3 : H3VirtualizationChoice;

	requirement h4 : H4ServiceCoLocation;
}
