# BACKLOG

Open and pending items only. Decisions that have already been taken are
recorded in `CHANGELOG.md`; this file is a work queue, not a decision record.

Items marked **Deviation:** compare this repo against `staylorx/dart-flutter-bible`
(`docs/` §1–§12) and are flagged for review, because the bible may itself be
wrong about the case in hand.

## Build, analysis and packaging problems

- **B1 — `EquatableMixin` is used in six value objects/failures**
  (`application_failure.dart`, `class_diagram_id.dart`, `conformance_report.dart`,
  `resolved_workflow.dart`, `symbol_table.dart`, `workflow_id.dart`).
  `equatable` resolves 2.0.8 today, so no deprecation fires and `dart analyze` is
  clean — but `EquatableMixin` is deprecated in `equatable` 2.1.0+ (use
  `with Equatable` instead). Convert before the next bump, or the analyze gate
  turns red.

- **B2 — `dart pub publish --dry-run` warns about the git-source dependency.**
  `pubspec.yaml` sets `publish_to: none`, so this is cosmetic today and becomes a
  blocker the day anyone flips `publish_to`; the bible explicitly sanctions the
  git dependency for a separate core repo.

- **B3 — `analysis_options.yaml` enables `prefer_const_constructors` and ignores
  it in the same file.** One of the two is wrong; leaving both means the next
  reader cannot tell which the author meant.

- **B4 — `analysis_options.yaml` carries obsolete analyzer options.**
  `analyzer.strong-mode:` is legacy and superseded by the `language: strict-*`
  block in the same file; `errors.missing_return` and `errors.invalid_assignment`
  are legacy ladders. Silently ignored config reads as if it were doing something.

- **B5 — `shouldly` is a declared dev_dependency that nothing imports.** Either
  the tests move to shouldly or the dependency comes out.

- **B6 — `README.md` is stale `dart create` template text.** It describes a CLI
  with a `bin/` that does not exist; the package is a clean-architecture
  application layer.

- **B8 — Dead commented-out `dartz` reexport in `lib/bpmn_application.dart`.**
  `dartz` is not a dependency (this project uses fpdart); the line has been dead
  since the dartz → fpdart move and now only misleads.

## Deviations from the dart-flutter-bible

- Deviation: pubspec.yaml - SDK constraint is `>3.11.0 <4.0.0`; bible §2 pins
  `'>=3.10.0 <4.0.0'`. The exclusive lower bound also skips 3.11.0 itself.
  Flagged because the bible's floor may simply be older than this package's real
  requirement.

- Deviation: lib/src/repositories/workflow_repository.dart - the public repository
  seam is `TaskEither<Exception, T>`; the bible requires `Future<Either<F,T>>`
  with `TaskEither` used only for internal composition and a typed per-layer
  sealed failure hierarchy rather than the raw `Exception` type.

- Deviation: lib/src/repositories/class_diagram_repository.dart - same seam
  divergence as `workflow_repository.dart` (`TaskEither<Exception, T>` exposed,
  raw `Exception` failure type).

- Deviation: lib/src/use_cases/load_workflow_use_case.dart - `call()` returns
  `TaskEither<ApplicationFailure, WorkflowCompilationUnit>` instead of
  `Future<Either<…>>`; the doc comment teaches `.call(...).run()`, so the
  deviation is deliberate-looking and needs a decision, not a silent patch.

- Deviation: lib/src/use_cases/load_class_diagram_use_case.dart - same as
  `load_workflow_use_case.dart`: public `call()` returns `TaskEither`, not
  `Future<Either>`.

- Deviation: lib/src/use_cases/save_workflow_use_case.dart - public `call()`
  returns `TaskEither` rather than `Future<Either>`, and takes a cargo object
  (`WorkflowCompilationUnit unit`) instead of discrete business parameters; bible
  §4/§11 ban cargo objects on use-case calls.

- Deviation: lib/src/use_cases/save_class_diagram_use_case.dart - same as
  `save_workflow_use_case.dart`: `TaskEither` seam plus a `CdCompilationUnit`
  cargo parameter.

- Deviation: lib/src/use_cases/check_conformance_use_case.dart - `call` takes a
  cargo object and returns `TaskEither` instead of `Future<Either>`; bible §4/§11
  require discrete business parameters and a `Future<Either>` public seam.

- Deviation: lib/src/use_cases/resolve_symbols_use_case.dart - `call` takes a
  cargo object and returns `TaskEither`; `_resolveImports` also mutates a captured
  `Map` inside a lazy fpdart callback, the exact laziness hazard the bible flags
  under testing pitfalls.

- Deviation: lib/src/use_cases/validate_workflow_use_case.dart - the only use
  case whose `call()` returns a plain `Either` rather than `TaskEither`,
  inconsistent with its six siblings while still not meeting the `Future<Either>`
  seam; also carries a `// TODO` and takes a cargo object.

- Deviation: lib/src/failures/application_failure.dart - eight classes in one
  file (sealed base plus seven subtypes); the bible requires one class per file.

- Deviation: lib/src/value_objects/conformance_report.dart - two classes in one
  file (`IncarnationMapping` and `ConformanceReport`).

- Deviation: test/bpmn_application_test.dart - assertions use `package:test`'s
  `expect()` throughout and never shouldly's `x.should.be(...)`; bible §6 selects
  shouldly and the BANNED list forbids mixing. The `shouldly` dependency is
  declared but unused.

- Deviation: test/bpmn_application_test.dart - test names are descriptive
  sentences rather than the Given/When/Then form the bible requires.

- Deviation: analysis_options.yaml - `public_member_api_docs` is not enabled and
  the file still carries `# todo: ignore` under `errors`; bible §2 makes both
  lints part of the analyze gate.

- Deviation: (whole repo) - there is no `dart_arch_test` boundary test; it is not
  a dev_dependency and no test invokes it. Bible §2/§9 make the onion direction +
  cycle-free boundary test a hard CI gate.

- Deviation: lib/bpmn_application.dart - the barrel opens with a bare `library;`
  followed by plain `//` prose; barrels are the one place the bible permits a
  file-level doc comment and expects terse `///` stating the package's contract
  and error style.

- Deviation: lib/src/use_cases/validate_workflow_use_case.dart - contains
  `// TODO: implement all CoCo checks.` in `_check`; bible §10 requires no
  TODO/FIXME in code, pending work belongs in this file.

- Deviation: (repo topology) - no `workspace:` root and no `resolution: workspace`
  in any pubspec; the package resolves standalone. `bpmn_domain` and
  `bpmn_infrastructure` are separate GitHub repos and the bible says workspaces do
  not span repos, so this may be a structural consequence rather than an
  oversight.

- Deviation: (repo topology) - the two repository contracts in
  `lib/src/repositories/` have no adapter and no shared contract suite in this
  repo; bible §1/§5 require at least two adapters per contract with contract tests
  living in core. Adapters presumably live in `bpmn_infrastructure`; the contract
  suite has no visible home in either repo.
