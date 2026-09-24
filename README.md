# vxmodels

SysML v2 system models for vxedge, plus `vxmodel`, the renderer that turns them into experiment workspaces (track M). The model is the design authority, and manifests remain the platform's only execution contract. It is not a general-purpose SysML v2 toolchain.

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Docs: CC BY 4.0](https://img.shields.io/badge/docs-CC%20BY%204.0-lightgrey.svg)](LICENSE-DOCS)
[![CI](https://github.com/vxedge/vxmodels/actions/workflows/ci.yml/badge.svg)](https://github.com/vxedge/vxmodels/actions/workflows/ci.yml)

vxedge is an open, all-software testbed for mapping 5G network slices onto zonal and central software-defined-vehicle (SDV) E/E architectures on a single machine. Every published number ships with the manifest and image digests that produced it.

## Layout

| Path | What |
|---|---|
| `models/requirements/` | H1–H4 as SysML `requirement`s, with `verify` links to frozen result archives |
| `models/vehicles/` | Vehicle E/E structure (`vx-vehicle-01`) |
| `models/experiments/` | Experiments as `analysis case`s, with their arms as variant points |
| `vxmodel/` | Rust renderer: model → vxedge workspace YAML, gated by `vxedge manifest validate` |

## Quickstart

```bash
cd vxmodel && cargo build && cargo test
./target/debug/vxmodel render --help
```

Design: [`docs/ARCHITECTURE.md`](https://github.com/vxedge/docs/blob/main/ARCHITECTURE.md) §6.3 and §15 (track M).

## Links

- Site: <https://vxedge.dev>
- Architecture: [`docs/ARCHITECTURE.md`](https://github.com/vxedge/docs/blob/main/ARCHITECTURE.md)
- Results: [`docs/RESULTS.md`](https://github.com/vxedge/docs/blob/main/RESULTS.md) · Roadmap: [`docs/ROADMAP.md`](https://github.com/vxedge/docs/blob/main/ROADMAP.md)
- Contributing: [CONTRIBUTING](https://github.com/vxedge/.github/blob/main/CONTRIBUTING.md) · Security: [SECURITY](https://github.com/vxedge/.github/blob/main/SECURITY.md)
- License: Apache-2.0 ([`LICENSE`](LICENSE)) for code; CC BY 4.0 ([`LICENSE-DOCS`](LICENSE-DOCS)) for docs, results, figures and models
