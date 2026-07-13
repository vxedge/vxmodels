// vxedge track M — M1 retroactive traceability model (verification half).
// One verification def per campaign, verify-linked to the hypotheses in
// hypotheses.sysml. Every evidence attribute is copied from the committed record
// (frozen summary / repro-check file / archive metadata.json) — including the honest
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
		     manifest digest was not retained (superseded by design — the retrofit
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
			attribute :>> manifestSha256 = "007ffd65472e (truncated prefix; full digest not retained — original archives overwritten by rerun)";
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
			attribute :>> verdict = "H4 HOLDS (comparative verdict robust; 0/6 metric pairs within original IQR — uniform same-day host drift)";
			attribute :>> frozenSummary = "vxperiments/results/exp-003/exp-003-repro-check-2026-07-13.md";
			attribute :>> caveats = "manifest changed between runs (optional_scrape_targets fix), hence digest differs; absolute-us figures are session properties, not testbed constants";
		}
	}
}
