# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `BACKLOG.md` — the open/pending work queue: build and analysis problems found
  by `dart pub get` / `dart analyze` / `dart test` / `dart format` /
  `dart pub publish --dry-run`, plus every divergence from the
  `staylorx/dart-flutter-bible` standards, each written as a
  `Deviation: <path> - <what diverges and why>` item for later review.
- `.gitattributes` — `* text=auto eol=lf`, so every text file is normalised to
  LF on commit regardless of which machine or tool wrote it.

### Changed

- Reconciled this file with `pubspec.yaml`. The manifest declares version
  `0.0.1`, so the previous `## 1.0.0` heading — which never corresponded to a
  release — was renamed to `## 0.0.1` and the "Initial version." line kept as its
  only entry. This also clears the `dart pub publish --dry-run` warning that the
  changelog did not mention the current version. A `1.0.0` section will be added
  when that version is actually cut.
- Wrapped the file in the Keep a Changelog preamble and section structure
  (`Added` / `Changed`) with `Unreleased` at the top; it previously had no
  preamble and no `Unreleased` section.
- No source, test or `analysis_options.yaml` change was made by the audit. The
  items it found are recorded in `BACKLOG.md` rather than fixed, so that
  deviations from the bible can be reviewed before anything is rewritten.

## [0.0.1] - 2026-02-23

### Added

- Initial version: clean-architecture application layer for the BPMN domain —
  `ApplicationFailure` sealed hierarchy, the `WorkflowId` / `ClassDiagramId` /
  `SymbolTable` / `ConformanceReport` / `ResolvedWorkflowUnit` value objects, the
  `WorkflowRepository` and `ClassDiagramRepository` contracts, and the load /
  save / resolve-symbols / validate / check-conformance use cases.

[Unreleased]: https://github.com/staylorx/bpmn_application/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/staylorx/bpmn_application/releases/tag/v0.0.1
