# Contributing to Tool Manager

Thank you for considering contributing! This document outlines how to set up the project locally, the coding conventions used, and the recommended pull request workflow.

## Setup

1. **Clone the repository**
   ```bash
   git clone <REPO_URL>
   cd tool-manager
   ```
2. **Install dependencies** – Tool Manager relies on Bash 5+ and standard POSIX utilities. To use the helper scripts, run:
   ```bash
   ./install.sh
   ```
   This installs Tool Manager into `~/.tool-manager` and sets up your shell.
3. **Install ShellCheck** – We recommend `shellcheck` for linting Bash scripts. On Ubuntu you can install it via:
   ```bash
   sudo apt-get install shellcheck
   ```
## Running Tests

The project uses [ShellCheck](https://www.shellcheck.net/) and [Bats](https://github.com/bats-core/bats-core) for basic testing.
To run the checks locally:

```bash
tm-dev-shellcheck
tm-dev-tests
```

## Coding Style

- Scripts are written for Bash and begin with `#!/usr/bin/env bash` or `#!/usr/bin/env env-tm-bash`.
- Use `set -Eeuo pipefail` for safer execution where appropriate.
- Indent with four spaces and avoid tabs.
- Keep functions small and well commented.
- Run `shellcheck` on any modified scripts and fix reported issues. You can suppress warnings with `# shellcheck disable=SCxxxx` when necessary.

## Pull Request Workflow

1. **Create a feature branch** from `main`.
2. Make your changes with clear, well-formatted commits.
3. Run `shellcheck` on all modified scripts to catch common errors.
4. Push your branch and open a pull request.
5. Ensure the PR description explains the purpose of the change and references any relevant issues.

We welcome improvements and fixes of all sizes. For large or potentially disruptive changes, open an issue or discussion first to ensure it aligns with the project goals.
