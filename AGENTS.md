# AGENTS.md

A composite GitHub Action that builds container images and publishes them to GHCR and Google Artifact Registry. All logic lives in `action.yml`. `README.md` documents its inputs, outputs, and publishing rules for workflow authors.

## Commands

- Lint: `pre-commit run --all-files`. Hooks live in `.pre-commit-config.yaml`. CI runs them on changed files in `.github/workflows/pre-commit.yml`.
- Release: run the `Release` workflow (`.github/workflows/release.yml`). Craft (`.craft.yml`) cuts the GitHub release. `scripts/bump-version.sh` is a no-op because the action has no version file.

## Invariants

- When you add, rename, or change an input or output in `action.yml`, update the tables in `README.md`.
- Add user-facing changes under `## Unreleased` in `CHANGELOG.md`.
- Pin third-party actions in `action.yml` to a full commit SHA with a version comment.
