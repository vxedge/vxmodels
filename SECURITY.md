# Security policy

Do not open a public issue for a security report.

Report vulnerabilities in vxmodels privately through GitHub's private vulnerability reporting:
open the repository's **Security** tab and choose **Report a vulnerability**
(https://github.com/vxedge/vxmodels/security/advisories/new).

In scope here: the `vxmodel` renderer, the validation script `scripts/validate-sysml.mjs`, and
model-integrity issues, such as a rendered manifest that reaches the testbed without clearing the
validation gate, or a render whose embedded model digest does not match the model that produced it.

Supported versions, response targets, and scope notes are in the vxedge organization
security policy: https://github.com/vxedge/.github/blob/main/SECURITY.md
