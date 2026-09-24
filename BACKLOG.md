# BACKLOG

Open and pending items only. Decisions that have already been taken are
recorded in `CHANGELOG.md`; this file is a work queue, not a decision record.

Audited 2026-09-24 on the Windows lane (Dart SDK 3.13.1, windows_x64) at commit
`8c55e0e`. Gate evidence for that run:

| Gate | Command | Result |
|---|---|---|
| Resolve | `dart pub get` | OK — 53 dependencies resolved |
| Analyze | `dart analyze` | 7 `info` diagnostics, all `deprecated_member_use` |
| Test | `dart test` | 52 of 52 pass |
| Format | `dart format --output=none --set-exit-if-changed .` | clean — 17 files, 0 changed |
| Publish | `dart pub publish --dry-run` | 1 warning (git-source dependency) |

Nothing here is auto-fixed. Items marked **Deviation:** compare this repo against
`staylorx/dart-flutter-bible` (`docs/01`–`docs/12`) and are flagged for review,
because the bible may itself be wrong about the case in hand.

---

## Build, analysis and packaging problems

### B1 — `dart analyze` is not clean: 7 `deprecated_member_use` infos

`equatable` 2.1.0 deprecates `EquatableMixin` ("use Equatable as a mixin
instead"). Seven value objects/failures mix it in:

- `lib/src/failures/application_failure.dart:32`
- `lib/src/value_objects/class_diagram_id.dart:22`
- `lib/src/value_objects/conformance_report.dart:17`
- `lib/src/value_objects/conformance_report.dart:70`
- `lib/src/value_objects/resolved_workflow.dart:23`
- `lib/src/value_objects/symbol_table.dart:35`
- `lib/src/value_objects/workflow_id.dart:24`

The bible's gate is `dart analyze --fatal-infos --fatal-warnings` reporting
**zero diagnostics of any severity**, so this repo would fail its own standard.
Fix is mechanical (`with EquatableMixin` → `with Equatable`, or bump equatable);
not done here because it is a source change and this card is an audit.

### B2 — `dart pub publish --dry-run` warns about the git-source dependency

```
* Don't depend on "bpmn_domain" from the git source. Use the hosted source instead.
```

Cosmetic today — `pubspec.yaml` sets `publish_to: none`, so the package is never
published. It becomes a blocker the day anyone flips `publish_to`, and the bible
explicitly sanctions the git dependency for a separate core repo, so the warning
may be unfixable by design. Decide which it is before publishing.

### B3 — `analysis_options.yaml` enables `prefer_const_constructors` and ignores it in the same file

```yaml
analyzer:
  errors:
    prefer_const_constructors: ignore   # line 22
linter:
  rules:
    - prefer_const_constructors          # line 31
```

One of the two is wrong. Either drop the rule (the current effective behaviour)
or drop the `ignore` — leaving both makes the config self-contradictory and the
next reader cannot tell which the author meant.

### B4 — `analysis_options.yaml` carries obsolete analyzer options

`analyzer.strong-mode: {implicit-casts, implicit-dynamic}` is legacy and is
already superseded by the `language: {strict-casts, strict-raw-types}` block in
the same file; `errors.missing_return` and `errors.invalid_assignment` are also
legacy ladders (`invalid_assignment: warning` is the default anyway). None of
them produced a diagnostic, which is the problem — they are silently ignored
configuration that reads as if it were doing something.

### B5 — `shouldly` is a declared dev_dependency that nothing uses

`pubspec.yaml:22` pins `shouldly: ^0.5.0+1` (correctly — the bible requires that
exact floor), but no file imports it. See the `expect()`-vs-shouldly deviation
below: the test suite uses `expect()`.
Either the tests move to shouldly or the dependency comes out.

### B6 — `README.md` is stale `dart create` template text

It reads "A sample command-line application providing basic argument parsing with
an entrypoint in `bin/`" — there is no `bin/` directory and the package is a
clean-architecture application layer, not a CLI. Every other gate is green while
the README describes a different project.

### B7 — No CI workflow

There is no `.github/` directory, so nothing runs `dart analyze` / `dart test`
per push or PR. The bible's bootstrap checklist (step 10) makes CI running
analyze + test on every PR part of the definition of a new project.

### B8 — Dead commented-out `dartz` import in the barrel

`lib/bpmn_application.dart:8` retains
`// reexport 'package:dartz/dartz.dart' hide Task, State, SymbolTable;`.
`dartz` is not a dependency (this project uses fpdart) and the line has been dead
since the dartz → fpdart move; it now only misleads.

---

## Deviations from the dart-flutter-bible

Format: `Deviation: <path> - <what diverges and why>`.

Deviation: pubspec.yaml - SDK constraint is `>3.11.0 <4.0.0`; bible §2 pins `'>=3.10.0 <4.0.0'` in every pubspec. The lower bound is also exclusive, so 3.11.0 itself is not covered even though the version reads as the floor. Flagged rather than fixed because the bible's floor may simply be older than this package's real requirement.

Deviation: lib/src/repositories/workflow_repository.dart - the public repository seam is `TaskEither<Exception, T>`. The bible requires the public seam to be `Future<Either<F,T>>` with `TaskEither` used only for internal composition and `.run()` called at the method boundary inside the layer, and it requires a typed per-layer sealed failure hierarchy rather than the raw `Exception` third-party type. As written, callers must build and run fpdart chains themselves and get an unstructured `Exception` they cannot pattern-match on.

Deviation: lib/src/repositories/class_diagram_repository.dart - same seam divergence as workflow_repository.dart: `TaskEither<Exception, T>` is exposed publicly and `Exception` is the failure type instead of a sealed per-layer hierarchy mapped upward at the adapter.

Deviation: lib/src/use_cases/load_workflow_use_case.dart - `call()` returns `TaskEither<ApplicationFailure, WorkflowCompilationUnit>` instead of `Future<Either<ApplicationFailure, WorkflowCompilationUnit>>`; bible §1/§4 put `.run()` at the public method boundary so consumers never build or run chains. The doc comment in this very file teaches `.call(...).run()` to callers, so the deviation is deliberate-looking and needs a decision, not a silent patch.

Deviation: lib/src/use_cases/load_class_diagram_use_case.dart - same as load_workflow_use_case.dart: public `call()` returns `TaskEither`, not `Future<Either>`.

Deviation: lib/src/use_cases/save_workflow_use_case.dart - public `call()` returns `TaskEither` rather than `Future<Either>`, and it takes a cargo object (`WorkflowCompilationUnit unit`) instead of discrete business parameters; bible §4/§11 ban cargo objects on usecase calls. `failIfExists` is correctly a named parameter.

Deviation: lib/src/use_cases/save_class_diagram_use_case.dart - same as save_workflow_use_case.dart: `TaskEither` seam plus a `CdCompilationUnit` cargo parameter.

Deviation: lib/src/use_cases/check_conformance_use_case.dart - `call(WorkflowCompilationUnit concreteUnit)` takes a cargo object and returns `TaskEither` instead of `Future<Either>`; bible §4/§11 require discrete business parameters and a `Future<Either>` public seam.

Deviation: lib/src/use_cases/resolve_symbols_use_case.dart - `call(WorkflowCompilationUnit unit)` takes a cargo object and returns `TaskEither` instead of `Future<Either>`; same two rules as above. Additionally `_resolveImports` mutates a captured `Map` inside a lazy fpdart callback (`_mergeClassifiers(..., typeMap)` inside `.flatMap`), which is the exact laziness hazard the bible calls out under testing pitfalls; it is correct only because the chain sequences the writes in order.

Deviation: lib/src/use_cases/validate_workflow_use_case.dart - the only use case whose `call()` returns a plain `Either` rather than `TaskEither`, so it is inconsistent with its six siblings while still not meeting the bible's `Future<Either>` seam. It also carries a `// TODO` (see the TODO deviation below) and takes a cargo object.

Deviation: lib/src/failures/application_failure.dart - eight classes in one file (the sealed `ApplicationFailure` base plus seven `final class` subtypes). The bible requires one class per file; a sealed hierarchy can still be split across files with `part`/`part of` if this is intentional.

Deviation: lib/src/value_objects/conformance_report.dart - two classes in one file (`IncarnationMapping` and `ConformanceReport`); the bible requires one class per file.

Deviation: test/bpmn_application_test.dart - assertions use `package:test`'s `expect()` throughout (70 calls) and never shouldly's `x.should.be(...)`; bible §6 selects shouldly as the assertion idiom and the BANNED list forbids mixing `expect()` with shouldly. The `shouldly` dependency is declared but unused, so the file currently reads as if the idiom was never adopted.

Deviation: test/bpmn_application_test.dart - test names are descriptive sentences ("stores fqn", "simpleName returns last segment", "returns Right(unit) when found") rather than the Given/When/Then form the bible requires.

Deviation: analysis_options.yaml - `public_member_api_docs` is not enabled and `todo:error` is absent, while the file explicitly carries `# todo: ignore` under `errors`. Bible §2/ENFORCEMENT makes both lints part of the analyze gate (`public_member_api_docs` + `implementation_imports` default-on) and the review checklist asks for no TODO/FIXME in code.

Deviation: (whole repo) - there is no `dart_arch_test` boundary test: it is not a dev_dependency and no test invokes it. Bible §2/§9 make the onion direction + cycle-free boundary test a hard CI gate that runs as part of `dart test`.

Deviation: (whole repo) - the package's error style is not declared. The bible's "ERROR STYLE IS DECLARED, LOUDLY" rule wants the choice (FP tuples vs plain exceptions) stated in the barrel doc comment, the README, and an `AGENTS.md` when the package deviates from the `Future<Either>` default. This package deviates (see the repository- and use-case-seam deviations above) and has none of the three: `README.md` is untouched template text and there is no `AGENTS.md` at all.

Deviation: lib/bpmn_application.dart - the barrel opens with a bare `library;` followed by plain `//` prose. Barrels are the one place the bible permits a file-level doc comment, and it is expected to be terse `///` text stating the package's contract and error style; as written the file also still lists "Re-add bpmn_domain export" style narrative rather than a contract statement.

Deviation: lib/src/use_cases/validate_workflow_use_case.dart - contains `// TODO: implement all CoCo checks.` in `_check`. Bible §10 requires no TODO/FIXME in code; pending work belongs in this file.

Deviation: (repo topology) - no `workspace:` root and no `resolution: workspace` in any pubspec; the package resolves standalone. Bible §2 expects a root pubspec listing every package with each member declaring `resolution: workspace`. Flagged rather than fixed because `bpmn_domain` and `bpmn_infrastructure` are separate GitHub repos and the bible itself says workspaces do not span repos, so this may be a structural consequence rather than an oversight.

Deviation: (repo topology) - the two repository contracts in `lib/src/repositories/` (`WorkflowRepository`, `ClassDiagramRepository`) have no adapter and no shared contract suite in this repo. Bible §1/§5 require at least two repository adapters per contract and a shared contract suite run against all of them, with contract tests living in core. Adapters presumably live in `bpmn_infrastructure`; the contract suite has no visible home in either repo.
