# AGENTS.md — php-ci

Agent router for the reusable PHP CI Docker image. Load only what your task needs.

> **Human docs:** [README.md](./README.md) · [CONTRIBUTING.md](./CONTRIBUTING.md) · [php-ci docs site](https://himanshuramavat.github.io/php-ci-docs/)  
> **Docs site source:** https://github.com/himanshuramavat/php-ci-docs

---

## Always load

| File | Why |
|---|---|
| `context/core.md` | Identity, registries, tags, conventions, quick commands |

---

## Task router

| Task | Load |
|---|---|
| Dockerfile / stages / build args / validation | `context/architecture.md` |
| GitHub Actions (test, publish, weekly rebuild) | `context/ci-workflows.md` |
| Consumer GitLab CI / T3Planet package pinning | `context/consumer-integration.md` |
| Add or change a PHP extension | `context/tasks/add-extension.md` |
| Cut a release / tag / publish | `context/tasks/release.md` |
| Local build + smoke tests | `context/tasks/local-test.md` |
| Deploy variant (`8.4-deploy`) | `context/architecture.md` (deploy target), `context/tasks/add-extension.md` (deploy checklist) |
| Security / Trivy / cosign | `SECURITY.md`, `context/ci-workflows.md` |

Prefer `context/` over re-reading the full README unless you need consumer copy-paste examples (`examples/`).

---

## Repo layout (agent-relevant)

```text
.
├── AGENTS.md
├── Dockerfile                    # php-runtime → final → deploy
├── scripts/
│   ├── verify-image.sh           # fail-fast extension list (must stay in sync)
│   ├── verify-deploy-image.sh
│   └── test-local.sh
├── test-local.sh                 # wrapper → scripts/test-local.sh
├── examples/                     # gitlab-ci + github-actions snippets
├── .github/workflows/
│   ├── test-php-ci.yml
│   ├── publish-php-ci.yml
│   └── weekly-rebuild.yml
└── context/                      # agent context (this tree)
```

---

## Quick commands

```bash
./test-local.sh
PHP_VERSIONS="8.4" ./test-local.sh
hadolint Dockerfile
```

Release: see `context/tasks/release.md`.

---

## Upstream

| Resource | URL |
|---|---|
| Image repo | https://github.com/himanshuramavat/php-ci |
| Docs repo | https://github.com/himanshuramavat/php-ci-docs |
| Published docs | https://himanshuramavat.github.io/php-ci-docs/ |

Downstream consumers (e.g. T3Planet TYPO3 extensions) pin the **published** image — see `context/consumer-integration.md`.
