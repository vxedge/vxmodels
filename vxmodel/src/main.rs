//! `vxmodel render` — turns a `.sysml` model into a manifest YAML
//! (docs/ARCHITECTURE.md §6), the second half of track M's model->manifest
//! pipeline (§6.3): `.sysml` -> `vxmodel render` -> YAML ->
//! `vxedge manifest validate --json`. Two model kinds, one command:
//! `--vehicle <model.sysml>` (M2, §6.2 `VehicleManifest`) or
//! `--experiment <model.sysml>` (M3, §6.1 `ExperimentManifest`).
//!
//! This is NOT a general SysML v2 parser. It's a narrow, pattern-based
//! extractor scoped to exactly the authoring conventions the
//! `sysml-authoring` skill enforces in this project's `.sysml` files (fixed
//! `attribute :>> name = value;` redefinition shape, fixed part/interface/
//! port nesting). A model that doesn't follow those conventions won't
//! render — that's a real, stated limitation, not a bug to silently paper
//! over (testbed-quality: fidelity caveats stated honestly). One consequence
//! worth stating plainly: extraction is single-file — a `.sysml` file's
//! `private import`s are resolved by the real SysIDE gate (gate 1) but NOT
//! by this text-pattern extractor, so a concrete (value-bearing) interface
//! def has to live in the same file it's rendered from. Purely structural
//! defs (part/port/enum shapes with no data) are fine to import, since only
//! their names are ever pattern-matched, never their bodies — see
//! `models/experiments/exp-pipeline-demo.sysml`'s header for a worked
//! example of the line between the two.
//!
//! `--experiment` is scoped narrower still, on purpose: it renders analysis
//! cases that are fully self-contained (every manifest field — zones,
//! traffic_profiles, telemetry, results — modeled 1:1), not the
//! methodology-only analysis cases in `phase1-analysis-cases.sysml` or
//! `exp-010-h2-real-slicing.sysml` (those model a varied dimension and a
//! campaign frame, not a topology) — rendering that second shape, and how an
//! open variant dimension collapses to one concrete manifest, is a separate,
//! larger design question left open in `vxmodels/TASKS.md` M3, not solved
//! here.
//!
//! Images are deliberately NOT modeled in `.sysml` (sysml-authoring skill:
//! "images/node IDs — zone/compute manifests own those, reference them,
//! never restate them"). No real vxzones/vxcompute manifest exists yet for
//! these nodes, so this renderer refuses to invent plausible-looking
//! image URLs; the caller supplies them via `--image <vxid>=<url>,<kind>`
//! and render fails loudly listing exactly which vxids are missing one.
//!
//! The model digest (§6.3: "YAML manifest + recorded model digest") is
//! recorded as a `# model-digest: sha256:...` YAML comment header, not a
//! manifest field — neither `VehicleManifest` nor `ExperimentManifest` has
//! a digest field, and adding one is a manifest-shape change that needs
//! ARCHITECTURE.md sign-off first (workspace CLAUDE.md hard rule), not
//! something this renderer decides unilaterally.

use sha2::{Digest, Sha256};
use std::collections::BTreeMap;
use std::path::PathBuf;
use std::process::ExitCode;

enum ModelKind {
    Vehicle(PathBuf),
    Experiment(PathBuf),
}

struct Args {
    model: ModelKind,
    out: PathBuf,
    images: BTreeMap<String, ImageSpec>,
}

struct ImageSpec {
    url: String,
    kind: String,
}

const USAGE: &str = "usage: vxmodel render (--vehicle | --experiment) <model.sysml> --out <manifest.yaml> [--image <vxid>=<url>,<kind> ...]";

fn parse_args() -> Result<Args, String> {
    let mut vehicle = None;
    let mut experiment = None;
    let mut out = None;
    let mut images = BTreeMap::new();
    let mut args = std::env::args().skip(1);
    // Subcommand: `vxmodel render ...` (the only one today).
    match args.next().as_deref() {
        Some("render") => {}
        Some(other) => return Err(format!("unknown subcommand `{other}` (expected `render`)")),
        None => return Err(USAGE.to_string()),
    }
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--vehicle" => {
                vehicle = Some(PathBuf::from(args.next().ok_or("--vehicle needs a value")?));
            }
            "--experiment" => {
                experiment = Some(PathBuf::from(
                    args.next().ok_or("--experiment needs a value")?,
                ));
            }
            "--out" => {
                out = Some(PathBuf::from(args.next().ok_or("--out needs a value")?));
            }
            "--image" => {
                let spec = args.next().ok_or("--image needs a value")?;
                let (vxid, rest) = spec
                    .split_once('=')
                    .ok_or_else(|| format!("--image `{spec}` must be `<vxid>=<url>,<kind>`"))?;
                let (url, kind) = rest
                    .split_once(',')
                    .ok_or_else(|| format!("--image `{spec}` must be `<vxid>=<url>,<kind>`"))?;
                images.insert(
                    vxid.to_string(),
                    ImageSpec {
                        url: url.to_string(),
                        kind: kind.to_string(),
                    },
                );
            }
            other => return Err(format!("unknown argument `{other}`")),
        }
    }
    let model = match (vehicle, experiment) {
        (Some(v), None) => ModelKind::Vehicle(v),
        (None, Some(e)) => ModelKind::Experiment(e),
        (None, None) => return Err(format!("--vehicle or --experiment is required\n{USAGE}")),
        (Some(_), Some(_)) => {
            return Err("--vehicle and --experiment are mutually exclusive".to_string());
        }
    };
    Ok(Args {
        model,
        out: out.ok_or("--out is required")?,
        images,
    })
}

fn main() -> ExitCode {
    let args = match parse_args() {
        Ok(a) => a,
        Err(e) => {
            eprintln!("error: {e}");
            return ExitCode::FAILURE;
        }
    };

    let model_path = match &args.model {
        ModelKind::Vehicle(p) | ModelKind::Experiment(p) => p,
    };
    let source = match std::fs::read_to_string(model_path) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("error: cannot read `{}`: {e}", model_path.display());
            return ExitCode::FAILURE;
        }
    };
    let digest = Sha256::digest(source.as_bytes());

    let yaml = match &args.model {
        ModelKind::Vehicle(p) => {
            let model = match extract::VehicleModel::parse(&source) {
                Ok(m) => m,
                Err(e) => {
                    eprintln!(
                        "error: cannot extract a vehicle structure from `{}`: {e}",
                        p.display()
                    );
                    return ExitCode::FAILURE;
                }
            };
            if let Some(code) = check_missing_images(model.required_vxids(), &args.images) {
                return code;
            }
            render::to_yaml(&model, &args.images, &digest)
        }
        ModelKind::Experiment(p) => {
            let model = match extract::AnalysisCase::parse(&source) {
                Ok(m) => m,
                Err(e) => {
                    eprintln!(
                        "error: cannot extract an analysis case from `{}`: {e}",
                        p.display()
                    );
                    return ExitCode::FAILURE;
                }
            };
            if let Some(code) = check_missing_images(model.required_vxids(), &args.images) {
                return code;
            }
            render::experiment_to_yaml(&model, &args.images, &digest)
        }
    };

    if let Some(parent) = args.out.parent()
        && !parent.as_os_str().is_empty()
        && let Err(e) = std::fs::create_dir_all(parent)
    {
        eprintln!("error: cannot create `{}`: {e}", parent.display());
        return ExitCode::FAILURE;
    }
    if let Err(e) = std::fs::write(&args.out, yaml) {
        eprintln!("error: cannot write `{}`: {e}", args.out.display());
        return ExitCode::FAILURE;
    }
    println!(
        "rendered {} -> {} (model-digest sha256:{:x})",
        model_path.display(),
        args.out.display(),
        digest
    );
    ExitCode::SUCCESS
}

/// Shared "never invent an image" gate for both model kinds. Returns `Some`
/// (the failure exit code) if any required vxid has no `--image` supplied.
fn check_missing_images(
    required: Vec<&str>,
    images: &BTreeMap<String, ImageSpec>,
) -> Option<ExitCode> {
    let missing: Vec<&str> = required
        .into_iter()
        .filter(|id| !images.contains_key(*id))
        .collect();
    if missing.is_empty() {
        None
    } else {
        eprintln!(
            "error: no --image supplied for: {} (this renderer never invents image URLs — see the file header doc)",
            missing.join(", ")
        );
        Some(ExitCode::FAILURE)
    }
}

/// Pattern-based extraction of the narrow `.sysml` subset this project's
/// vehicle structure models use. See the module doc for the scope caveat.
mod extract {
    #[derive(Debug)]
    pub struct SliceDef {
        pub id: String,
        pub vlan: u32,
        pub min_rate_mbps: u32,
        pub max_rate_mbps: u32,
        pub priority: u32,
    }

    #[derive(Debug)]
    pub struct NodeDef {
        pub part_name: String,
        pub node_type: String,
        pub function: String,
        pub slice_id: String,
    }

    #[derive(Debug)]
    pub struct ZoneDef {
        pub role_kebab: String,
        pub node: NodeDef,
    }

    #[derive(Debug)]
    pub struct VehicleModel {
        pub id: String,
        pub name: String,
        pub zones: Vec<ZoneDef>,
        pub compute_gpu: String,
        pub slices: Vec<SliceDef>,
    }

    #[derive(Debug)]
    pub struct TrafficProfileDef {
        pub source: String,
        pub target: String,
        pub bandwidth_mbps: u32,
        pub payload_bytes: u32,
    }

    #[derive(Debug)]
    pub struct ResultsDef {
        pub artifact_dir: String,
        pub upload: bool,
    }

    /// An `analysis def` extracted 1:1 into `ExperimentManifest` shape (§6.1).
    /// See the module doc: scoped to fully self-contained analysis cases only
    /// (every field modeled), not the methodology-only shape
    /// `exp-010-h2-real-slicing.sysml` uses.
    #[derive(Debug)]
    pub struct AnalysisCase {
        pub id: String,
        pub name: String,
        pub duration_s: u32,
        pub zone: ZoneDef,
        pub slices: Vec<SliceDef>,
        pub traffic: TrafficProfileDef,
        pub scrape_target: String,
        pub results: ResultsDef,
    }

    impl AnalysisCase {
        /// vxids this model needs an `--image` for: the one zone node.
        pub fn required_vxids(&self) -> Vec<&str> {
            vec![self.zone.node.part_name.as_str()]
        }

        pub fn parse(src: &str) -> Result<Self, String> {
            let case_block = analysis_case_block(src)?;
            let slices = extract_slices(src)?;

            let id = attr_decl_string(case_block, "id")
                .ok_or("analysis case has no `attribute id : String = \"...\";`")?;
            let name = attr_decl_string(case_block, "name")
                .ok_or("analysis case has no `attribute name : String = \"...\";`")?;
            let duration_s = attr_decl_number(case_block, "durationS")
                .ok_or("analysis case has no `attribute durationS : Natural = N;`")?;

            let (_, z_open, z_close) = block_at(case_block, ": VehicleZone {", 0)
                .ok_or("analysis case has no `: VehicleZone { ... }` zone")?;
            let zone = parse_zone(&case_block[z_open + 1..z_close], &slices)?;

            let (_, t_open, t_close) = block_at(case_block, ": TrafficProfile {", 0)
                .ok_or("analysis case has no `: TrafficProfile { ... }` usage")?;
            let traffic_block = &case_block[t_open + 1..t_close];
            let traffic = TrafficProfileDef {
                source: attr_string(traffic_block, "source")
                    .ok_or("traffic profile has no `attribute :>> source = \"...\";`")?,
                target: attr_string(traffic_block, "target")
                    .ok_or("traffic profile has no `attribute :>> target = \"...\";`")?,
                bandwidth_mbps: attr_number(traffic_block, "bandwidthMbps")
                    .ok_or("traffic profile has no `attribute :>> bandwidthMbps = N;`")?,
                payload_bytes: attr_number(traffic_block, "payloadBytes")
                    .ok_or("traffic profile has no `attribute :>> payloadBytes = N;`")?,
            };

            let scrape_target = attr_decl_string(case_block, "scrapeTarget")
                .ok_or("analysis case has no `attribute scrapeTarget : String = \"...\";`")?;

            let (_, r_open, r_close) = block_at(case_block, ": ResultsPolicy {", 0)
                .ok_or("analysis case has no `: ResultsPolicy { ... }` usage")?;
            let results_block = &case_block[r_open + 1..r_close];
            let results = ResultsDef {
                artifact_dir: attr_string(results_block, "artifactDir")
                    .ok_or("results policy has no `attribute :>> artifactDir = \"...\";`")?,
                upload: attr_bool(results_block, "upload")
                    .ok_or("results policy has no `attribute :>> upload = true|false;`")?,
            };

            Ok(AnalysisCase {
                id,
                name,
                duration_s,
                zone,
                slices,
                traffic,
                scrape_target,
                results,
            })
        }
    }

    /// Finds the first `analysis def <Name> { ... }` and returns its body.
    /// The case name itself isn't needed by the renderer (the case's own
    /// `id`/`name` attributes carry the manifest identity), so it's discarded.
    fn analysis_case_block(src: &str) -> Result<&str, String> {
        let marker = "analysis def ";
        let name_start = src
            .find(marker)
            .ok_or("no `analysis def ... { ... }` found")?
            + marker.len();
        let open = src[name_start..]
            .find('{')
            .map(|i| name_start + i)
            .ok_or("analysis case has no body")?;
        let close = find_matching_brace(src.as_bytes(), open)
            .ok_or("analysis case block is unterminated")?;
        Ok(&src[open + 1..close])
    }

    impl VehicleModel {
        /// vxids this model needs an `--image` for: every zone node plus the
        /// one central compute node, in render order.
        pub fn required_vxids(&self) -> Vec<&str> {
            let mut out: Vec<&str> = self
                .zones
                .iter()
                .map(|z| z.node.part_name.as_str())
                .collect();
            out.push("centralCompute");
            out
        }

        pub fn parse(src: &str) -> Result<Self, String> {
            let slices = extract_slices(src)?;

            let (_, v_open, v_close) = block_at(src, ": Vehicle {", 0)
                .ok_or("no `part <name> : Vehicle { ... }` usage found")?;
            let vehicle_block = &src[v_open + 1..v_close];

            let id = attr_string(vehicle_block, "id")
                .ok_or("Vehicle usage has no `attribute :>> id = \"...\";`")?;
            let name = attr_string(vehicle_block, "vehicleName")
                .ok_or("Vehicle usage has no `attribute :>> vehicleName = \"...\";`")?;

            let mut zones = Vec::new();
            let mut from = 0;
            while let Some((_, z_open, z_close)) = block_at(vehicle_block, ": VehicleZone {", from)
            {
                let zone_block = &vehicle_block[z_open + 1..z_close];
                zones.push(parse_zone(zone_block, &slices)?);
                from = z_close + 1;
            }
            if zones.is_empty() {
                return Err("Vehicle usage has no `: VehicleZone { ... }` zone slots".to_string());
            }

            let (_, c_open, c_close) = block_at(vehicle_block, ": CentralComputeNode {", 0)
                .ok_or("Vehicle usage has no `: CentralComputeNode { ... }` compute slot")?;
            let compute_block = &vehicle_block[c_open + 1..c_close];
            let compute_gpu = attr_string(compute_block, "gpu")
                .ok_or("CentralComputeNode usage has no `attribute :>> gpu = \"...\";`")?;

            Ok(VehicleModel {
                id,
                name,
                zones,
                compute_gpu,
                slices,
            })
        }
    }

    fn parse_zone(zone_block: &str, slices: &[SliceDef]) -> Result<ZoneDef, String> {
        let role = enum_value(zone_block, "role", "ZoneRoleKind")
            .ok_or("zone usage has no `attribute :>> role = ZoneRoleKind::...;`")?;
        let role_kebab = camel_to_kebab(&role);

        let (_, n_open, n_close) = block_at(zone_block, ": ZoneNode :>> nodes {", 0)
            .ok_or("zone usage has no `: ZoneNode :>> nodes { ... }` node")?;
        // The part usage name sits just before " : ZoneNode" — walk back
        // from the marker start over the preceding identifier.
        let marker_start = zone_block[..n_open + 1]
            .rfind(": ZoneNode :>> nodes {")
            .unwrap();
        let part_name = preceding_identifier(&zone_block[..marker_start])
            .ok_or("could not read the zone node's part usage name")?;
        let node_block = &zone_block[n_open + 1..n_close];

        let node_type = attr_string(node_block, "nodeType")
            .ok_or("zone node has no `attribute :>> nodeType = \"...\";`")?;
        let function = attr_string(node_block, "function")
            .ok_or("zone node has no `attribute :>> function = \"...\";`")?;
        let port_type = after_marker_identifier(node_block, "port :>> slicePort : ")
            .ok_or("zone node has no `port :>> slicePort : <PortType>;`")?;
        let port_slice_id = camel_to_kebab(
            port_type
                .strip_suffix("SlicePort")
                .ok_or_else(|| format!("port type `{port_type}` doesn't end in `SlicePort`"))?,
        );
        if !slices.iter().any(|s| s.id == port_slice_id) {
            return Err(format!(
                "node `{part_name}` binds to slice `{port_slice_id}` (from port type `{port_type}`), \
                 but no `{port_slice_id}` slice interface def was found"
            ));
        }

        Ok(ZoneDef {
            role_kebab,
            node: NodeDef {
                part_name,
                node_type,
                function,
                slice_id: port_slice_id,
            },
        })
    }

    fn extract_slices(src: &str) -> Result<Vec<SliceDef>, String> {
        let marker = " :> SliceInterface {";
        let mut out = Vec::new();
        let mut from = 0;
        while let Some(rel) = src[from..].find(marker) {
            let marker_start = from + rel;
            let name = preceding_identifier(&src[..marker_start])
                .ok_or("could not read a slice interface def's name")?;
            let id = camel_to_kebab(name.strip_suffix("SliceInterface").ok_or_else(|| {
                format!("interface def `{name}` doesn't end in `SliceInterface`")
            })?);
            let open = src[marker_start..]
                .find('{')
                .map(|i| marker_start + i)
                .unwrap();
            let close = find_matching_brace(src.as_bytes(), open)
                .ok_or_else(|| format!("unterminated `{name}` interface block"))?;
            let block = &src[open + 1..close];

            let vlan = attr_number(block, "vlan")
                .ok_or_else(|| format!("`{name}` has no `attribute :>> vlan = N;`"))?;
            let q_open_rel = block
                .find("qos {")
                .ok_or_else(|| format!("`{name}` has no `qos {{ ... }}` block"))?;
            let q_open = block[q_open_rel..]
                .find('{')
                .map(|i| q_open_rel + i)
                .unwrap();
            let q_close = find_matching_brace(block.as_bytes(), q_open)
                .ok_or_else(|| format!("`{name}`'s qos block is unterminated"))?;
            let qos_block = &block[q_open + 1..q_close];
            let min_rate_mbps = attr_number(qos_block, "minRateMbps")
                .ok_or_else(|| format!("`{name}`'s qos has no minRateMbps"))?;
            let max_rate_mbps = attr_number(qos_block, "maxRateMbps")
                .ok_or_else(|| format!("`{name}`'s qos has no maxRateMbps"))?;
            let priority = attr_number(qos_block, "priority")
                .ok_or_else(|| format!("`{name}`'s qos has no priority"))?;

            out.push(SliceDef {
                id,
                vlan,
                min_rate_mbps,
                max_rate_mbps,
                priority,
            });
            from = close + 1;
        }
        if out.is_empty() {
            return Err(
                "no `... :> SliceInterface { ... }` slice interface defs found".to_string(),
            );
        }
        Ok(out)
    }

    /// Find the first occurrence of `marker` at/after `from`, then the
    /// brace-matched block starting at the next `{` after it. Returns
    /// (marker_start, open_brace_idx, close_brace_idx), indices into `src`.
    fn block_at(src: &str, marker: &str, from: usize) -> Option<(usize, usize, usize)> {
        let rel = src[from..].find(marker)?;
        let marker_start = from + rel;
        let open = src[marker_start..].find('{')? + marker_start;
        let close = find_matching_brace(src.as_bytes(), open)?;
        Some((marker_start, open, close))
    }

    /// Byte-depth brace matcher that skips `//` line comments, `/* */` block
    /// comments, and `"..."` string literals so braces inside doc comments
    /// or (hypothetically) string values never desync the count.
    fn find_matching_brace(src: &[u8], open_idx: usize) -> Option<usize> {
        debug_assert_eq!(src[open_idx], b'{');
        let mut i = open_idx + 1;
        let mut depth = 1i32;
        while i < src.len() {
            match src[i] {
                b'/' if i + 1 < src.len() && src[i + 1] == b'/' => {
                    while i < src.len() && src[i] != b'\n' {
                        i += 1;
                    }
                }
                b'/' if i + 1 < src.len() && src[i + 1] == b'*' => {
                    i += 2;
                    while i + 1 < src.len() && !(src[i] == b'*' && src[i + 1] == b'/') {
                        i += 1;
                    }
                    i += 2;
                }
                b'"' => {
                    i += 1;
                    while i < src.len() && src[i] != b'"' {
                        i += 1;
                    }
                    i += 1;
                }
                b'{' => {
                    depth += 1;
                    i += 1;
                }
                b'}' => {
                    depth -= 1;
                    i += 1;
                    if depth == 0 {
                        return Some(i - 1);
                    }
                }
                _ => i += 1,
            }
        }
        None
    }

    fn attr_string(block: &str, name: &str) -> Option<String> {
        let marker = format!("attribute :>> {name} = \"");
        let start = block.find(&marker)? + marker.len();
        let end = block[start..].find('"')? + start;
        Some(block[start..end].to_string())
    }

    fn attr_number(block: &str, name: &str) -> Option<u32> {
        let marker = format!("attribute :>> {name} = ");
        let start = block.find(&marker)? + marker.len();
        let end = block[start..].find(|c: char| !c.is_ascii_digit())? + start;
        block[start..end].parse().ok()
    }

    fn attr_bool(block: &str, name: &str) -> Option<bool> {
        let marker = format!("attribute :>> {name} = ");
        let start = block.find(&marker)? + marker.len();
        if block[start..].starts_with("true") {
            Some(true)
        } else if block[start..].starts_with("false") {
            Some(false)
        } else {
            None
        }
    }

    /// A plain (non-redefinition) `attribute {name} : String = "value";`
    /// declaration, the shape top-level analysis-case attributes use (they
    /// have no supertype feature to redefine, unlike `Vehicle`'s `:>> id`).
    fn attr_decl_string(block: &str, name: &str) -> Option<String> {
        let marker = format!("attribute {name} : String = \"");
        let start = block.find(&marker)? + marker.len();
        let end = block[start..].find('"')? + start;
        Some(block[start..end].to_string())
    }

    fn attr_decl_number(block: &str, name: &str) -> Option<u32> {
        let marker = format!("attribute {name} : Natural = ");
        let start = block.find(&marker)? + marker.len();
        let end = block[start..].find(|c: char| !c.is_ascii_digit())? + start;
        block[start..end].parse().ok()
    }

    fn enum_value(block: &str, name: &str, enum_name: &str) -> Option<String> {
        let marker = format!("attribute :>> {name} = {enum_name}::");
        let start = block.find(&marker)? + marker.len();
        let end = block[start..].find(|c: char| !(c.is_ascii_alphanumeric() || c == '_'))? + start;
        Some(block[start..end].to_string())
    }

    fn after_marker_identifier(block: &str, marker: &str) -> Option<String> {
        let start = block.find(marker)? + marker.len();
        let end = block[start..].find(|c: char| !(c.is_ascii_alphanumeric() || c == '_'))? + start;
        Some(block[start..end].to_string())
    }

    /// Walk backward over the identifier immediately preceding `prefix`'s end
    /// (skipping trailing whitespace), e.g. `...part adasProbeFl ` -> `adasProbeFl`.
    fn preceding_identifier(prefix: &str) -> Option<String> {
        let trimmed = prefix.trim_end();
        let end = trimmed.len();
        let start = trimmed
            .rfind(|c: char| !(c.is_ascii_alphanumeric() || c == '_'))
            .map(|i| i + 1)
            .unwrap_or(0);
        if start >= end {
            None
        } else {
            Some(trimmed[start..end].to_string())
        }
    }

    /// `adasProbeFl` -> `adas-probe-fl`, `frontLeft` -> `front-left`,
    /// `Adas` -> `adas`.
    pub fn camel_to_kebab(s: &str) -> String {
        let mut out = String::new();
        for (i, c) in s.char_indices() {
            if c.is_uppercase() {
                if i != 0 {
                    out.push('-');
                }
                out.extend(c.to_lowercase());
            } else {
                out.push(c);
            }
        }
        out
    }
}

/// Renders an `extract::VehicleModel` into `VehicleManifest`-shaped YAML
/// (docs/ARCHITECTURE.md §6.2) by hand (no serde round-trip through
/// vxedge-core: that would make this crate depend on a sibling repo's
/// internals across the workspace/repo boundary, which the two repos'
/// independent-clone structure doesn't assume). Output is validated for
/// real via `vxedge manifest validate --json` as a separate step (the
/// sysml-authoring skill's documented double-gate command), not by this
/// renderer — same decoupling reason.
mod render {
    use super::ImageSpec;
    use super::extract::VehicleModel;
    use sha2::Sha256;
    use sha2::digest::Output;
    use std::collections::BTreeMap;
    use std::fmt::Write as _;

    pub fn to_yaml(
        model: &VehicleModel,
        images: &BTreeMap<String, ImageSpec>,
        digest: &Output<Sha256>,
    ) -> String {
        let mut y = String::new();
        let _ = writeln!(y, "# model-digest: sha256:{digest:x}");
        let _ = writeln!(
            y,
            "# rendered by vxmodel from a .sysml source — do not hand-edit; edit the model and re-render."
        );
        let _ = writeln!(y, "vehicle:");
        let _ = writeln!(y, "  id: {}", yaml_str(&model.id));
        let _ = writeln!(y, "  name: {}", yaml_str(&model.name));
        let _ = writeln!(y);

        let _ = writeln!(y, "network:");
        let _ = writeln!(y, "  slices:");
        for s in &model.slices {
            let _ = writeln!(y, "    - id: {}", s.id);
            let _ = writeln!(y, "      mode: vlan");
            let _ = writeln!(y, "      vlan: {}", s.vlan);
            let _ = writeln!(
                y,
                "      qos: {{ min_rate_mbps: {}, max_rate_mbps: {}, priority: {} }}",
                s.min_rate_mbps, s.max_rate_mbps, s.priority
            );
        }
        let _ = writeln!(y);

        let _ = writeln!(y, "zones:");
        for z in &model.zones {
            let node = &z.node;
            let node_id = format!("node-{}", super::extract::camel_to_kebab(&node.part_name));
            let img = &images[&node.part_name];
            let _ = writeln!(y, "  - id: vxzone-{}-01", z.role_kebab);
            let _ = writeln!(y, "    role: {}", z.role_kebab);
            let _ = writeln!(y, "    nodes:");
            let _ = writeln!(y, "      - id: {node_id}");
            let _ = writeln!(y, "        type: {}", node.node_type);
            let _ = writeln!(y, "        function: {}", yaml_str(&node.function));
            let _ = writeln!(
                y,
                "        image: {{ url: {}, kind: {} }}",
                yaml_str(&img.url),
                img.kind
            );
            let _ = writeln!(y, "        network:");
            let _ = writeln!(y, "          - iface: eth0");
            let _ = writeln!(y, "            slice: {}", node.slice_id);
        }
        let _ = writeln!(y);

        let compute_img = &images["centralCompute"];
        let _ = writeln!(y, "compute:");
        let _ = writeln!(y, "  - id: vxcompute-central-01");
        let _ = writeln!(y, "    name: central");
        let _ = writeln!(
            y,
            "    image: {{ url: {}, kind: {} }}",
            yaml_str(&compute_img.url),
            compute_img.kind
        );
        let _ = writeln!(y, "    resources: {{ gpu: {} }}", model.compute_gpu);

        y
    }

    /// Renders an `extract::AnalysisCase` into `ExperimentManifest`-shaped
    /// YAML (§6.1). Same hand-written-YAML, no-serde-round-trip approach as
    /// `to_yaml`, same reason (no cross-repo Rust dependency).
    pub fn experiment_to_yaml(
        model: &super::extract::AnalysisCase,
        images: &BTreeMap<String, ImageSpec>,
        digest: &Output<Sha256>,
    ) -> String {
        let mut y = String::new();
        let _ = writeln!(y, "# model-digest: sha256:{digest:x}");
        let _ = writeln!(
            y,
            "# rendered by vxmodel from a .sysml source — do not hand-edit; edit the model and re-render."
        );
        let _ = writeln!(y, "experiment:");
        let _ = writeln!(y, "  id: {}", yaml_str(&model.id));
        let _ = writeln!(y, "  name: {}", yaml_str(&model.name));
        let _ = writeln!(y, "  duration_s: {}", model.duration_s);
        let _ = writeln!(
            y,
            "  results_prefix: {}",
            yaml_str(&model.results.artifact_dir)
        );
        let _ = writeln!(y);

        let _ = writeln!(y, "network:");
        let _ = writeln!(y, "  slices:");
        for s in &model.slices {
            let _ = writeln!(y, "    - id: {}", s.id);
            let _ = writeln!(y, "      mode: vlan");
            let _ = writeln!(y, "      vlan: {}", s.vlan);
            let _ = writeln!(
                y,
                "      qos: {{ min_rate_mbps: {}, max_rate_mbps: {}, priority: {} }}",
                s.min_rate_mbps, s.max_rate_mbps, s.priority
            );
        }
        let _ = writeln!(y);

        let z = &model.zone;
        let node = &z.node;
        let node_id = format!("node-{}", super::extract::camel_to_kebab(&node.part_name));
        let zone_id = format!("vxzone-{}-01", z.role_kebab);
        let img = &images[&node.part_name];
        let _ = writeln!(y, "zones:");
        let _ = writeln!(y, "  - id: {zone_id}");
        let _ = writeln!(y, "    role: {}", z.role_kebab);
        let _ = writeln!(y, "    nodes:");
        let _ = writeln!(y, "      - id: {node_id}");
        let _ = writeln!(y, "        type: {}", node.node_type);
        let _ = writeln!(y, "        function: {}", yaml_str(&node.function));
        let _ = writeln!(
            y,
            "        image: {{ url: {}, kind: {} }}",
            yaml_str(&img.url),
            img.kind
        );
        let _ = writeln!(y, "        network:");
        let _ = writeln!(y, "          - iface: eth0");
        let _ = writeln!(y, "            slice: {}", node.slice_id);
        let _ = writeln!(y);

        let _ = writeln!(y, "traffic_profiles:");
        let _ = writeln!(y, "  {}-load:", z.role_kebab);
        let _ = writeln!(y, "    source: {}", yaml_str(&model.traffic.source));
        let _ = writeln!(y, "    target: {}", yaml_str(&model.traffic.target));
        let _ = writeln!(y, "    bandwidth_mbps: {}", model.traffic.bandwidth_mbps);
        let _ = writeln!(y, "    payload_bytes: {}", model.traffic.payload_bytes);
        let _ = writeln!(y);

        let _ = writeln!(y, "telemetry:");
        let _ = writeln!(y, "  prometheus:");
        let _ = writeln!(y, "    scrape_targets:");
        let _ = writeln!(y, "      - {}", yaml_str(&model.scrape_target));
        let _ = writeln!(y);

        let _ = writeln!(y, "results:");
        let _ = writeln!(
            y,
            "  artifact_dir: {}",
            yaml_str(&model.results.artifact_dir)
        );
        let _ = writeln!(y, "  upload: {}", model.results.upload);

        y
    }

    fn yaml_str(s: &str) -> String {
        format!("{s:?}")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renders_the_real_vx_vehicle_01_model() {
        let source = std::fs::read_to_string(
            std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
                .join("../models/vehicles/vx-vehicle-01.sysml"),
        )
        .expect("vx-vehicle-01.sysml exists");
        let model = extract::VehicleModel::parse(&source).expect("model extracts cleanly");

        assert_eq!(model.id, "vx-vehicle-01");
        assert_eq!(model.zones.len(), 4);
        assert_eq!(model.slices.len(), 2);
        assert!(model.slices.iter().any(|s| s.id == "adas" && s.vlan == 101));
        assert!(
            model
                .slices
                .iter()
                .any(|s| s.id == "infotainment" && s.vlan == 103)
        );

        let roles: Vec<&str> = model.zones.iter().map(|z| z.role_kebab.as_str()).collect();
        assert_eq!(
            roles,
            vec!["front-left", "front-right", "rear-left", "rear-right"]
        );

        let rear_left = model
            .zones
            .iter()
            .find(|z| z.role_kebab == "rear-left")
            .unwrap();
        assert_eq!(rear_left.node.slice_id, "infotainment");
        assert_eq!(rear_left.node.node_type, "infotainment");

        let front_left = model
            .zones
            .iter()
            .find(|z| z.role_kebab == "front-left")
            .unwrap();
        assert_eq!(front_left.node.slice_id, "adas");

        assert_eq!(model.compute_gpu, "passthrough");
    }

    #[test]
    fn to_yaml_produces_a_manifest_shaped_document() {
        let source = std::fs::read_to_string(
            std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
                .join("../models/vehicles/vx-vehicle-01.sysml"),
        )
        .unwrap();
        let model = extract::VehicleModel::parse(&source).unwrap();
        let mut images = BTreeMap::new();
        for vxid in model.required_vxids() {
            images.insert(
                vxid.to_string(),
                ImageSpec {
                    url: "local/placeholder:test".to_string(),
                    kind: "container".to_string(),
                },
            );
        }
        let digest = Sha256::digest(source.as_bytes());
        let yaml = render::to_yaml(&model, &images, &digest);

        assert!(yaml.starts_with("# model-digest: sha256:"));
        assert!(yaml.contains("vehicle:"));
        assert!(yaml.contains("id: \"vx-vehicle-01\""));
        assert!(yaml.contains("vxzone-front-left-01"));
        assert!(yaml.contains("slice: adas"));
        assert!(yaml.contains("slice: infotainment"));
        assert!(yaml.contains("vxcompute-central-01"));
        assert!(yaml.contains("gpu: passthrough"));
    }

    #[test]
    fn missing_slice_interface_for_a_port_is_a_parse_error_not_a_panic() {
        let bad = r#"
package X {
  abstract interface def SliceInterface { attribute vlan : Natural; }
  abstract interface def AdasSliceInterface :> SliceInterface {
    attribute :>> vlan = 101;
    attribute qos { attribute :>> minRateMbps = 1; attribute :>> maxRateMbps = 2; attribute :>> priority = 3; }
  }
  part vxVehicle01 : Vehicle {
    attribute :>> id = "x";
    attribute :>> vehicleName = "x";
    part :>> frontLeftZone : VehicleZone {
      attribute :>> role = ZoneRoleKind::frontLeft;
      part n1 : ZoneNode :>> nodes {
        attribute :>> nodeType = "ecu";
        attribute :>> function = "f";
        port :>> slicePort : NotARealSlicePort;
      }
    }
    part :>> centralCompute : CentralComputeNode {
      attribute :>> gpu = "passthrough";
    }
  }
}
"#;
        let err = extract::VehicleModel::parse(bad).unwrap_err();
        assert!(err.contains("no `not-a-real` slice"), "got: {err}");
    }

    #[test]
    fn renders_the_real_pipeline_demo_case() {
        let source = std::fs::read_to_string(
            std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
                .join("../models/experiments/exp-pipeline-demo.sysml"),
        )
        .expect("exp-pipeline-demo.sysml exists");
        let model = extract::AnalysisCase::parse(&source).expect("model extracts cleanly");

        assert_eq!(model.id, "exp-pipeline-demo");
        assert_eq!(model.name, "vxmodel pipeline demo");
        assert_eq!(model.duration_s, 30);
        assert_eq!(model.zone.role_kebab, "front-left");
        assert_eq!(model.zone.node.slice_id, "demo");
        assert_eq!(model.slices.len(), 1);
        assert_eq!(model.slices[0].vlan, 101);
        assert_eq!(model.traffic.source, "vxzone-demo-01:node-demo-01");
        assert_eq!(model.traffic.target, "internet");
        assert_eq!(model.traffic.bandwidth_mbps, 50);
        assert_eq!(model.scrape_target, "127.0.0.1:9801");
        assert_eq!(model.results.artifact_dir, "results/exp-pipeline-demo");
        assert!(!model.results.upload);
    }

    #[test]
    fn experiment_to_yaml_produces_a_manifest_shaped_document() {
        let source = std::fs::read_to_string(
            std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
                .join("../models/experiments/exp-pipeline-demo.sysml"),
        )
        .unwrap();
        let model = extract::AnalysisCase::parse(&source).unwrap();
        let mut images = BTreeMap::new();
        for vxid in model.required_vxids() {
            images.insert(
                vxid.to_string(),
                ImageSpec {
                    url: "local/vxprobe:host-process".to_string(),
                    kind: "container".to_string(),
                },
            );
        }
        let digest = Sha256::digest(source.as_bytes());
        let yaml = render::experiment_to_yaml(&model, &images, &digest);

        assert!(yaml.starts_with("# model-digest: sha256:"));
        assert!(yaml.contains("experiment:"));
        assert!(yaml.contains("id: \"exp-pipeline-demo\""));
        assert!(yaml.contains("duration_s: 30"));
        assert!(yaml.contains("vxzone-front-left-01"));
        assert!(yaml.contains("slice: demo"));
        assert!(yaml.contains("traffic_profiles:"));
        assert!(yaml.contains("bandwidth_mbps: 50"));
        assert!(yaml.contains("telemetry:"));
        assert!(yaml.contains("127.0.0.1:9801"));
        assert!(yaml.contains("results:"));
        assert!(yaml.contains("upload: false"));
    }

    #[test]
    fn missing_analysis_case_is_a_parse_error_not_a_panic() {
        let bad = "package X { part def Y { } }";
        let err = extract::AnalysisCase::parse(bad).unwrap_err();
        assert!(err.contains("no `analysis def"), "got: {err}");
    }
}
