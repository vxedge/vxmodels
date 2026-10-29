# vxmodels

SysML v2 system models for vxedge, plus `vxmodel`, the renderer that turns them into experiment workspaces (track M). It is not a general-purpose SysML v2 toolchain.

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Docs: CC BY 4.0](https://img.shields.io/badge/docs-CC%20BY%204.0-lightgrey.svg)](LICENSE-DOCS)
[![CI](https://github.com/vxedge/vxmodels/actions/workflows/ci.yml/badge.svg)](https://github.com/vxedge/vxmodels/actions/workflows/ci.yml)

vxedge is an open, all-software testbed for mapping 5G network slices onto zonal and central software-defined-vehicle (SDV) E/E architectures on a single machine. Every published number ships with the manifest and image digests that produced it.

## What "model-governed" means here

vxedge is a *model-governed executable virtual prototype*. The SysML v2 models in this repo are the design authority: requirements H1-H4 with `verify` links to frozen results, the vehicle E/E structure, and experiments as analysis cases. The testbed never reads a model. It runs manifests only, and every manifest it runs from a model is rendered by `vxmodel` and must clear two gates:

1. **Model gate:** the `.sysml` source parses and type-checks against the SysML v2 standard library (`scripts/validate-sysml.mjs`).
2. **Manifest gate:** the rendered workspace passes `vxedge manifest validate --json`.

A render embeds the sha256 of the model that produced it, so a result traces back to one model version. Models cite results only by manifest digest or by a public [`vxperiments`](https://github.com/vxedge/vxperiments) path. Design: [`docs/ARCHITECTURE.md` §6.3](https://github.com/vxedge/docs/blob/main/ARCHITECTURE.md#63-model-governance-sysml-v2-track-m-vxmodels). Track status: [`docs/FACTS.md`](https://github.com/vxedge/docs/blob/main/FACTS.md#tracks) (`track.m`).

## Install

Prebuilt `vxmodel` for Linux x86-64 and ARM64 is attached to each [release](https://github.com/vxedge/vxmodels/releases). Each release carries `SHA256SUMS` and build provenance. The binaries are built on Ubuntu 24.04 (glibc 2.39), so they run on 24.04 and newer. Verifying provenance needs `gh` 2.49 or newer.

```bash
gh release download -R vxedge/vxmodels --pattern '*'                                     # both archives + SHA256SUMS
sha256sum --ignore-missing -c SHA256SUMS                                                 # must say OK
gh attestation verify vxmodels-*-x86_64-unknown-linux-gnu.tar.gz -R vxedge/vxmodels     # aarch64 on ARM
tar xzf vxmodels-*-x86_64-unknown-linux-gnu.tar.gz
cd vxmodels-*-x86_64-unknown-linux-gnu                                                   # vxmodel, LICENSE, NOTICE
```

Or build from source (the crate pins its own toolchain in `vxmodel/rust-toolchain.toml`):

```bash
cd vxmodel && cargo build --locked && cargo test
```

## Validate a model

The model gate needs Node 22, the SysIDE language server and the SysML v2 standard library. CI fetches both at pinned versions and checks their sha256; the URLs and digests are in [`.github/workflows/ci.yml`](.github/workflows/ci.yml). Neither is committed here.

```bash
SYSIDE_JS=<path>/syside-languageserver.js \
SYSML_STDLIB=<path>/sysml.library \
node scripts/validate-sysml.mjs models/**/*.sysml
# PASS: all files parse and type-check clean
```

## Render a model

```bash
vxmodel render --experiment models/experiments/exp-pipeline-demo.sysml \
  --out rendered/exp-pipeline-demo.yaml \
  --image demoNode=local/vxprobe:host-process,container
vxedge manifest validate --manifest rendered/exp-pipeline-demo.yaml --json
```

`--vehicle <model.sysml>` renders a vehicle structure model instead. Images are always an explicit `--image <vxid>=<url>,<kind>` input: the model never carries them. `vxmodel render --help` prints the full usage.

## Layout

| Path | What |
|---|---|
| `models/requirements/` | H1-H4 as SysML `requirement`s, with `verify` links to frozen result archives |
| `models/vehicles/` | Vehicle E/E structure (`vx-vehicle-01`) |
| `models/experiments/` | Experiments as `analysis case`s, with their arms as variant points |
| `vxmodel/` | Rust renderer: model to vxedge workspace YAML, gated by `vxedge manifest validate` |
| `scripts/validate-sysml.mjs` | Headless parse and type-check gate (drives SysIDE over LSP) |

## Links

- Site: <https://vxedge.dev>
- Architecture: [`docs/ARCHITECTURE.md`](https://github.com/vxedge/docs/blob/main/ARCHITECTURE.md) · Facts: [`docs/FACTS.md`](https://github.com/vxedge/docs/blob/main/FACTS.md)
- Results: [`docs/RESULTS.md`](https://github.com/vxedge/docs/blob/main/RESULTS.md) · Roadmap: [`docs/ROADMAP.md`](https://github.com/vxedge/docs/blob/main/ROADMAP.md)
- Contributing: [CONTRIBUTING](https://github.com/vxedge/.github/blob/main/CONTRIBUTING.md) · Security: [SECURITY.md](SECURITY.md) · Changelog: [CHANGELOG.md](CHANGELOG.md) · Cite: [CITATION.cff](CITATION.cff)

## License

Code is Apache-2.0 ([`LICENSE`](LICENSE)). SysML models, documentation, results and figures are CC BY 4.0 ([`LICENSE-DOCS`](LICENSE-DOCS)). [`NOTICE`](NOTICE) states the same split.
