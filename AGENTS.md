# AGENTS.md

Pure-Dart clean-architecture **application layer** for BPMN: use cases, repository contracts, and value objects. Depends on `bpmn_domain` (git ref `main`) for the domain model; no parsing or I/O of its own.

## Gate

No CI workflow is configured; the gate is:

```sh
dart analyze --fatal-infos --fatal-warnings   # → "No issues found!" (zero diagnostics of any severity)
dart test                                     # → all pass
```

`analysis_options.yaml` enables `strict-casts`, `strict-raw-types`, `always_declare_return_types`, `avoid_print`.

## Key paths

| Thing | Location |
|---|---|
| Remote | `https://github.com/staylorx/bpmn_application.git` (depends on `bpmn_domain` `main`) |
| Barrel | `lib/bpmn_application.dart` (`library;`, re-exports the whole `bpmn_domain` barrel + own `lib/src/`) |
| Use cases | `lib/src/use_cases/` |
| Repository contracts | `lib/src/repositories/` |
| Value objects | `lib/src/value_objects/` |
| Failures | `lib/src/failures/application_failure.dart` |

## Error style

`Either<DomainFailure, T>` / `TaskEither` (fpdart `^1.2.0`) across use-case and repository seams — repository contracts return `TaskEither`, use cases surface typed failures, never exceptions.

## Wiring / deviations

- The barrel **re-exports `bpmn_domain` wholesale**, so symbols from the domain layer (e.g. `Unit`) collide at any use-case that imports both — hide the colliding name rather than renaming.
- Tests use `shouldly` (plus `mocktail`).
