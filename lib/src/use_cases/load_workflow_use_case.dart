import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../failures/application_failure.dart';
import '../repositories/workflow_repository.dart';
import '../value_objects/workflow_id.dart';

/// Retrieves a single [WorkflowCompilationUnit] from the repository by its
/// fully qualified name.
///
/// This is the primary read path for workflows.  The infrastructure layer
/// is responsible for populating the [WorkflowRepository] (typically by
/// parsing `.wfm` files and calling [SaveWorkflowUseCase]).
///
/// ## Returns
///
/// - `Right(unit)` — the compilation unit was found.
/// - `Left(WorkflowNotFound)` — no unit with the given [WorkflowId] exists.
///
/// ## Example
///
/// ```dart
/// final useCase = LoadWorkflowUseCase(repository: repo);
/// final result = await useCase
///     .execute(WorkflowId('de.monticore.bpmn.examples.OrderToDeliveryWorkflow'))
///     .run();
/// result.fold(
///   (f) => print('Error: ${f.message}'),
///   (unit) => print('Loaded: ${unit.fullyQualifiedName}'),
/// );
/// ```
class LoadWorkflowUseCase {
  final WorkflowRepository _repository;

  const LoadWorkflowUseCase({required WorkflowRepository repository})
    : _repository = repository;

  /// Executes the load.
  ///
  /// [id] — the fully qualified name of the workflow to retrieve.
  TaskEither<ApplicationFailure, WorkflowCompilationUnit> execute(WorkflowId id) =>
      _repository
          .findById(id)
          .mapLeft((e) => WorkflowNotFound(id) as ApplicationFailure)
          .flatMap(
            (opt) => opt.match(
              () => TaskEither.left(WorkflowNotFound(id)),
              TaskEither.right,
            ),
          );
}
