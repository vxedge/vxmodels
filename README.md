# vxmodels

Part of the **vxedge** research platform.

**Purpose:** SysML v2 system models (requirements traceability, vehicle structure,
analysis cases, scenarios) and the `vxmodel` renderer that generates vxedge YAML
manifests from them — the model-governance layer (track M) over the executable
virtual prototype.

The model is the design authority; manifests remain the platform's sole execution
contract (`vxedge manifest validate` gates every rendered manifest).

See [vxedge/docs](https://github.com/vxedge/docs) for research plan and architecture
(`ARCHITECTURE.md` §6.3, §15 track M).
