// vxedge track M: M1 retroactive traceability model (verification half).
// One verification def per campaign, verify-linked to the hypotheses in
// hypotheses.sysml. Every evidence attribute is copied from the committed record
// (frozen summary / repro-check file / archive metadata.json), including the honest
// gaps. Digests are the join key (sysml-authoring rule: link by digest, never name).

package VxedgeVerification {
	private import ScalarValues::*;
	private import VxedgeHypotheses::*;

	attribute def CampaignEvidence {
		doc /* One measurement campaign's committed evidence record. manifestSha256 is
		     the experiment-manifest digest embedded in each results archive
		     (vxperiments/results/<exp>/…, metadata.json); frozenSummary is the
		     committed human-readable record. */
		attribute experimentId : String;
		attribute manifestSha256 : String;
		attribute archiveCount : Natural;
		attribute campaignDate : String;
		attribute verdict : String;
		attribute frozenSummary : String;
		attribute caveats : String;
	}

	verification def Exp001SliceIsolation {
		doc /* exp-001: adas p99 RTT 71.7 µs under 600 mbit offered infotainment
		     overload vs 77.3 µs baseline (0.93x), zero loss at every load level. */
		objective {
			verify h1;
		}
		attribute campaign : CampaignEvidence {
			attribute :>> experimentId = "exp-001";
			attribute :>> manifestSha256 = "e51721c1a5a044d7da4ce4baf5c8aa69329c4f6dae0ee76f5ad1659c559d36ea";
			attribute :>> archiveCount = 25;
			attribute :>> campaignDate = "2026-07-10";
			attribute :>> verdict = "H1 HOLDS";
			attribute :>> frozenSummary = "vxperiments/results/exp-001/exp-001-summary.md";
			attribute :>> caveats = "shared-host gateway; non-PREEMPT_RT kernel; userspace timestamps";
		}
		attribute reproCheck : CampaignEvidence {
			attribute :>> experimentId = "exp-001";
			attribute :>> manifestSha256 = "e51721c1a5a044d7da4ce4baf5c8aa69329c4f6dae0ee76f5ad1659c559d36ea";
			attribute :>> archiveCount = 25;
			attribute :>> campaignDate = "2026-07-13";
			attribute :>> verdict = "REPRODUCIBLE (14/15 metric/load pairs within original IQR; one borderline p99 at load0)";
			attribute :>> frozenSummary = "vxperiments/results/exp-001/exp-001-repro-check-2026-07-13.md";
			attribute :>> caveats = "uniform small downward session shift; H1 verdict unaffected (0.93x vs 0.95x)";
		}
	}

	verification def Exp002PackagingComparison {
		doc /* exp-002 (single-arm retrofit, re-run 2026-07-13, superseding the original
		     concurrent-arm campaign in place): p50 container 54.3 µs, libvirt VM
		     +12.0 µs, qemu-microvm +59.2 µs, zero loss. The pre-retrofit campaign's
		     manifest digest was not retained (superseded by design: the retrofit
		     changed the manifest); recorded here as the honest provenance state. */
		objective {
			verify h3;
		}
		attribute campaign : CampaignEvidence {
			attribute :>> experimentId = "exp-002";
			attribute :>> manifestSha256 = "a8aa539dc04a49de49ff4990c1ba086fb917b077008cffbd29fffbead621ebe6";
			attribute :>> archiveCount = 15;
			attribute :>> campaignDate = "2026-07-13";
			attribute :>> verdict = "H3 HOLDS (container < libvirt < qemu-microvm)";
			attribute :>> frozenSummary = "vxperiments/results/exp-002/exp-002-summary.md";
			attribute :>> caveats = "supersedes the 2026-07-11 concurrent-arm campaign in place; libvirt p50 corrected 74.5->66.3 us once isolated";
		}
	}

	verification def Exp002bPackagingDecomposition {
		doc /* exp-002b: decomposes exp-002's gap. Machine type (q35 vs microvm) shows
		     no measurable effect (dp50 -0.3 µs, within IQR); the drivers are virtio
		     transport (MMIO vs PCI, dp50 -26.0 µs, dominant), vhost-net (-9.5 µs), and
		     management layer (libvirt faster than raw QEMU, -17.3 µs). Two independent
		     campaigns, same manifest sha, same verdicts, zero loss both. */
		objective {
			verify h3;
		}
		attribute campaign : CampaignEvidence {
			attribute :>> experimentId = "exp-002b";
			attribute :>> manifestSha256 = "625840eeeb0cab3b9f34ec35d28ea3babf6b1eba4411c85255848b41ec722a38";
			attribute :>> archiveCount = 30;
			attribute :>> campaignDate = "2026-07-12";
			attribute :>> verdict = "H3 DECOMPOSED (transport dominates; machine type: no effect)";
			attribute :>> frozenSummary = "vxperiments/results/exp-002b/exp-002b-summary.md";
			attribute :>> caveats = "campaign #1 invalidated (concurrent-arm CPU contention) and discarded; #2/#3 clean, second run after 8-angle code-review hardening";
		}
	}

	verification def Exp003OtaCoLocation {
		doc /* exp-003: adas p50 45.8 µs under sustained OTA delivery burst vs 47.2 µs
		     baseline (within IQR), zero loss both arms, ~355 deliveries/rep zero
		     failures. Measures host-level contention, not gateway-QoS-enforced network
		     contention (v1 OTA transport rides no manifest slice yet). PROVENANCE
		     NOTE, recorded honestly: the original campaign's archives were overwritten
		     in place by the repro-check rerun; the original manifest digest survives
		     only as the truncated prefix recorded in the frozen summary. */
		objective {
			verify h4;
		}
		attribute campaign : CampaignEvidence {
			attribute :>> experimentId = "exp-003";
			attribute :>> manifestSha256 = "007ffd65472e (truncated prefix; full digest not retained; original archives overwritten by rerun)";
			attribute :>> archiveCount = 10;
			attribute :>> campaignDate = "2026-07-13";
			attribute :>> verdict = "H4 HOLDS";
			attribute :>> frozenSummary = "vxperiments/results/exp-003/exp-003-summary.md";
			attribute :>> caveats = "host-level contention, not slice-enforced network contention; shared-host gateway; non-PREEMPT_RT";
		}
		attribute reproCheck : CampaignEvidence {
			attribute :>> experimentId = "exp-003";
			attribute :>> manifestSha256 = "5dc4c2a6b8604c83458261c9e48bec503d00b28806a2473ad5b699105f92f348";
			attribute :>> archiveCount = 10;
			attribute :>> campaignDate = "2026-07-13";
			attribute :>> verdict = "H4 HOLDS (comparative verdict robust; 0/6 metric pairs within original IQR; uniform same-day host drift)";
			attribute :>> frozenSummary = "vxperiments/results/exp-003/exp-003-repro-check-2026-07-13.md";
			attribute :>> caveats = "manifest changed between runs (optional_scrape_targets fix), hence digest differs; absolute-us figures are session properties, not testbed constants";
		}
	}

	verification def Exp010RealSlicingVerification {
		doc /* exp-010, snssai arm only; the vlan arm of this comparison is exp-001
		     itself (identical topology/probe methodology, no same-day rerun; see
		     Exp001SliceIsolation above). **H2 HOLDS**, final verdict 2026-07-18:
		     adas p99 growth baseline->600mbit is 1.00x (345.3 us -> 345.9 us,
		     essentially flat) vs vlan's own 0.93x, comfortably inside the 1.10x
		     tolerance: real, kernel-level per-slice isolation
		     (gateway::provision::apply_fiveg_slice_qos), zero loss at every load
		     level, 25 archives, 5 reps x 5 loads, 60s window/1000pps (60k
		     samples/point). Three attributes below record the full trajectory, not
		     just the final answer: `campaign` (pre-fix, DOES NOT HOLD, root cause
		     identified: no per-slice QoS enforcement anywhere in fiveg),
		     `htbFixRetest` (the HTB fix landed, but still formally borderline:
		     0.007 below the tolerance threshold, on an unmitigated host),
		     `finalRetest` (host-confound mitigation: cpu governor pinning, cpu
		     affinity and randomized load order per rep; landed, H2 HOLDS). A
		     specific, reproducible elevation at the 250mbit load point persists
		     across all three campaigns; randomizing load order in the final
		     campaign confirmed it's load-correlated (ran at every one of the five
		     possible sequence positions across the five reps and stayed elevated
		     regardless) rather than a host-scheduling artifact tied to run order,
		     but its magnitude shrunk to within the calibrated noise floor
		     (vxperiments/results/exp-010-noise-floor-2026-07-18/, 15 reps zero
		     stimulus, p99 median 338.9us IQR 14.3us range 316.7-355.3us), so it
		     does not change the verdict. */
		objective {
			verify h2;
		}
		attribute campaign : CampaignEvidence {
			attribute :>> experimentId = "exp-010";
			attribute :>> manifestSha256 = "d8a988e515434edb7d93ab21ee15457ea737c234dc774922d72fceccda0b1a83";
			attribute :>> archiveCount = 25;
			attribute :>> campaignDate = "2026-07-18";
			attribute :>> verdict = "H2 DOES NOT HOLD (root cause: fiveg has no per-slice QoS/5QI/AMBR differentiation yet; unequal comparison, not evidence against the hypothesis)";
			attribute :>> frozenSummary = "vxperiments/results/exp-010-no-qos-2026-07-18/exp-010-summary.md";
			attribute :>> caveats = "shared-host gateway; non-PREEMPT_RT kernel; userspace timestamps; TrafficService's spawned vxprobe send has no live --metrics yet (final aggregate JSON only); vlan arm not rerun (exp-001's own frozen numbers, identical mechanism)";
		}
		attribute htbFixRetest : CampaignEvidence {
			attribute :>> experimentId = "exp-010";
			attribute :>> manifestSha256 = "aab3effc3749eacc8cf69bf2e5151240948fc01a523333a95f935b90812a637c";
			attribute :>> archiveCount = 25;
			attribute :>> campaignDate = "2026-07-18";
			attribute :>> verdict = "H2 DOES NOT HOLD (formally borderline: snssai 1.03x vs a 1.023x threshold, a 0.007 margin; HTB mechanism fix landed and independently verified live, but host measured on powersave governor, no cpu pinning, fixed load-order sequence every rep)";
			attribute :>> frozenSummary = "vxperiments/results/exp-010-qos-fix-unmitigated-2026-07-18/exp-010-summary.md";
			attribute :>> caveats = "same manifest as finalRetest (qos declared on both slices); only the runner's host-confound mitigations differ between this and finalRetest; empirically confirmed live (not assumed) that Open5GS's own subscriber AMBR field is recorded but not enforced by its software UPF, hence the HTB-based fix instead of 5QI/ARP/AMBR rendering";
		}
		attribute finalRetest : CampaignEvidence {
			attribute :>> experimentId = "exp-010";
			attribute :>> manifestSha256 = "aab3effc3749eacc8cf69bf2e5151240948fc01a523333a95f935b90812a637c";
			attribute :>> archiveCount = 25;
			attribute :>> campaignDate = "2026-07-18";
			attribute :>> verdict = "H2 HOLDS (adas p99 growth baseline->600mbit: snssai 1.00x vs vlan 0.93x, well inside the 1.10x tolerance)";
			attribute :>> frozenSummary = "vxperiments/results/exp-010/exp-010-summary.md";
			attribute :>> caveats = "shared-host gateway; non-PREEMPT_RT kernel; userspace timestamps; cpu pinning is best-effort (vxedged + host-side vxprobe/vxtraffic taskset to reserved cores, podman containers incl. adas-probe's own reflector not cpuset-restricted); 250mbit load point still shows a reproducible elevation (confirmed load-correlated via randomized order, not position-correlated) but within the calibrated noise floor, not large enough to change the verdict";
		}
	}
}
