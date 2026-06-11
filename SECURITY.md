# Security Policy

`php-ci` is a base Docker image consumed by many TYPO3 / Laravel / PHP pipelines, so
vulnerabilities here can have downstream blast radius. Reports are taken seriously.

## Supported versions

| Tag pattern | Example | Support |
|---|---|---|
| Rolling PHP minor | `8.4`, `8.3`, `8.2`, `8.1` | Rebuilt weekly with upstream Debian + PHP security patches |
| `latest` | `latest` | Alias of the highest supported PHP rolling tag (`8.4`) |
| Immutable release | `<php>-v<x.y.z>` (e.g. `8.4-v1.3.0`) | Frozen at publish time; superseded by newer releases, not patched in place |

Only the **current** rolling tags receive fixes. Pin an immutable tag for reproducibility,
but track the [Releases](https://github.com/himanshuramavat/php-ci/releases) page and rebase
onto a newer immutable tag to pick up security updates.

## Reporting a vulnerability

- **Preferred:** open a private advisory via **GitHub Security Advisories**
  (repo → *Security* → *Report a vulnerability*).
- **Email:** the maintainer (see [README](./README.md#maintainer)).

Please do **not** open public issues for undisclosed vulnerabilities.

### What to include

- Affected tag(s) / PHP version(s) and image digest.
- Affected package or extension and CVE id if known.
- Reproduction steps or proof of concept.

### Response targets

| Stage | Target |
|---|---|
| Acknowledgement | 3 business days |
| Initial assessment | 7 business days |
| Fix or mitigation for rolling tags | best effort, prioritised by severity |

## Image scanning

CI runs [Trivy](https://trivy.dev/) on every built image and fails on **CRITICAL/HIGH**
fixable OS/library CVEs (`ignore-unfixed: true`). Non-exploitable kernel-header findings
(`linux-libc-dev`) are suppressed in [`.trivyignore`](./.trivyignore) — the kernel does not
run inside the container.

## Verifying image signatures

Published immutable tags are signed with [cosign](https://docs.sigstore.dev/) (keyless,
GitHub OIDC). Verify before deploying:

```bash
cosign verify \
  --certificate-identity-regexp 'https://github.com/himanshuramavat/php-ci/.+' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/himanshuramavat/php-ci:8.4-v1.3.0
```
