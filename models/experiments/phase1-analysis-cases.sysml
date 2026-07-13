// vxedge track M — M3 calibration set: the four phase-1 campaigns retro-modeled as
// analysis cases. These are the worked examples future (including LLM-authored)
// experiments are patterned on; the digest join keys and verdicts live in
// VxedgeVerification (models/requirements/verification.sysml) — this file models the
// experiment *designs*: subject configuration, the varied dimension, the fixed frame.
//
// Variant rule (sysml-authoring skill): arms are values of an enumerated dimension,
// never copy-pasted analysis cases. In SysML v2 an enum def IS a variation (its
// literals are the variants), so dimension attributes are typed by the enum directly —
// wrapping them in a `variation` usage is illegal (a variation may not specialize
// another variation; found empirically against SysIDE 0.9.1).

package VxedgePhase1Experiments {
	private import ScalarValues::*;

	// --- the enumerated dimensions phase-1 arms vary over -----------------------

	enum def PackagingBackend {
		doc /* Node packaging per ARCHITECTURE §9: the H3 experimental variable. */
		container;
		qemuMicrovm;
		libvirtVm;
	}

	enum def VirtioTransport {
		doc /* exp-002b decomposition dimension: the dominant latency driver. */
		mmio;
		pci;
	}

	enum def QemuMachine {
		doc /* exp-002b decomposition dimension: shown to have NO measurable effect. */
		q35;
		microvm;
	}

	enum def InterferenceSource {
		doc /* What contends with the adas slice during the measured window. */
		none;
		infotainmentTraffic;
		otaDeliveryBurst;
	}

	// --- shared experiment frame -------------------------------------------------

	attribute def CampaignFrame {
		doc /* The fixed methodology frame every phase-1 campaign shares
		     (experiment-methodology skill): repetitions, warmup, probe window,
		     probe rate — identical across compared arms by construction. */
		attribute repetitions : Natural;
		attribute warmupS : Natural;
		attribute probeWindowS : Natural;
		attribute probePps : Natural;
		attribute isolation : String;
	}

	// --- analysis cases, one per campaign ----------------------------------------

	analysis def Exp001SliceIsolation {
		doc /* H1: adas p99 RTT under stepped infotainment overload vs baseline.
		     Varied: offered infotainment load (0..600 mbit, 5 levels). Fixed: slice
		     QoS (100 mbit guaranteed adas), topology, probe parameters. */
		attribute campaignFrame : CampaignFrame {
			attribute :>> repetitions = 5;
			attribute :>> warmupS = 10;
			attribute :>> probeWindowS = 60;
			attribute :>> probePps = 1000;
			attribute :>> isolation = "single experiment, load stepped per point";
		}
		attribute loadLevelsMbps : Natural[1..*] = (0, 100, 250, 400, 600);
		attribute interference : InterferenceSource = InterferenceSource::infotainmentTraffic;
	}

	analysis def Exp002PackagingComparison {
		doc /* H3: identical probe path, packaging backend varied. One zone per arm
		     since the 2026-07-13 single-arm retrofit — exactly one arm's zone is up
		     during its measurement. */
		attribute campaignFrame : CampaignFrame {
			attribute :>> repetitions = 5;
			attribute :>> warmupS = 10;
			attribute :>> probeWindowS = 60;
			attribute :>> probePps = 1000;
			attribute :>> isolation = "single-arm";
		}
		attribute backend : PackagingBackend {
			doc /* The varied dimension: one arm per literal (3 arms). */
		}
	}

	analysis def Exp002bPackagingDecomposition {
		doc /* H3 decomposition: six arms isolating WHY packaging matters. Pairwise
		     deltas: transport = microvm-pci vs microvm-mmio; machine = q35-pci vs
		     microvm-pci; vhost = q35-vhost vs q35-pci; management = libvirt-q35 vs
		     q35-pci. Finding: transport dominates; machine type is noise. */
		attribute campaignFrame : CampaignFrame {
			attribute :>> repetitions = 5;
			attribute :>> warmupS = 10;
			attribute :>> probeWindowS = 60;
			attribute :>> probePps = 1000;
			attribute :>> isolation = "single-arm";
		}
		attribute transport : VirtioTransport {
			doc /* Varied dimension (dominant driver: mmio vs pci). */
		}
		attribute machine : QemuMachine {
			doc /* Varied dimension (finding: no measurable effect). */
		}
		attribute vhostEnabled : Boolean {
			doc /* Varied dimension: q35-vhost vs q35-pci arms. */
		}
		attribute libvirtManaged : Boolean {
			doc /* Varied dimension: libvirt-q35 vs q35-pci arms. */
		}
	}

	analysis def Exp003OtaCoLocation {
		doc /* H4: adas SLA with vs without a sustained OTA delivery burst co-located
		     on the host. Two arms over InterferenceSource: none (baseline) vs
		     otaDeliveryBurst. Same adas slice/QoS/probe as exp-001, so baselines are
		     directly comparable across the two campaigns. */
		attribute campaignFrame : CampaignFrame {
			attribute :>> repetitions = 5;
			attribute :>> warmupS = 10;
			attribute :>> probeWindowS = 60;
			attribute :>> probePps = 1000;
			attribute :>> isolation = "single-arm";
		}
		attribute interference : InterferenceSource {
			doc /* Varied dimension: none (baseline arm) vs otaDeliveryBurst. */
		}
		attribute artifactMb : Natural = 5;
	}
}
