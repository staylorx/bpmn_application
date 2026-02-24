import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../failures/application_failure.dart';
import '../repositories/workflow_repository.dart';
import '../value_objects/workflow_id.dart';

/// Persists a [WorkflowCompilationUnit] to the repository.
///
/// This use case is typically called by the infrastructure (parser) layer
/// after successfully parsing a `.wfm` file into a domain object.  It may
/// also be used by tooling that programmatically constructs workflow units.
///
/// ## Save semantics
///
/// The repository contract uses **upsert** semantics — saving a unit whose
/// FQN already exists replaces the existing entry.  If your scenario requires
/// detecting duplicates (e.g. to warn the user that a workflow is being
/// overwritten), set [failIfExists] to `true`.
///
/// ## Returns
///
/// - `Right(unit)` — the unit was saved successfully.
/// - `Left(WorkflowAlreadyExists)` — [failIfExists] is `true` and a unit
///   with the same FQN already exists.
///
/// ## Example
///
/// ```dart
/// final useCase = SaveWorkflowUseCase(repository: repo);
/// final result = await useCase.execute(compilationUnit).run();
/// result.fold(
///   (f) => print('Save failed: ${f.message}'),
///   (unit) => print('Saved: ${unit.fullyQualifiedName}'),
/// );
/// ```
class SaveWorkflowUseCase {
  final WorkflowRepository _repository;

  const SaveWorkflowUseCase({required WorkflowRepository repository})
    : _repository = repository;

  /// Executes the save.
  ///
  /// [unit] — the workflow compilation unit to persist.
  /// [failIfExists] — when `true`, returns [WorkflowAlreadyExists] if a unit
  ///   with the same FQN already exists instead of overwriting it.
  TaskEither<ApplicationFailure, WorkflowCompilationUnit> execute(
    WorkflowCompilationUnit unit, {
    bool failIfExists = false,
  }) {
    final id = WorkflowId(unit.fullyQualifiedName);

    if (!failIfExists) {
      return _repository
          .save(unit)
          .mapLeft((e) => WorkflowAlreadyExists(id) as ApplicationFailure);
    }

    return _repository
        .findById(id)
        .mapLeft((e) => WorkflowNotFound(id) as ApplicationFailure)
        .flatMap(
          (opt) => opt.match(
            () => _repository
                .save(unit)
                .mapLeft(
                  (e) => WorkflowAlreadyExists(id) as ApplicationFailure,
                ),
            (_) => TaskEither.left(WorkflowAlreadyExists(id)),
          ),
        );
  }
}
