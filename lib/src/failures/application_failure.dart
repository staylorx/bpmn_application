import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:equatable/equatable.dart';

import '../value_objects/class_diagram_id.dart';
import '../value_objects/workflow_id.dart';

/// The abstract base for all application-layer failures.
///
/// Application failures are distinct from [WorkflowFailure] (which captures
/// domain-level CoCo violations found during static analysis of a process).
/// [ApplicationFailure] covers problems that occur during use-case execution:
/// missing resources, repository collisions, and unresolved cross-references
/// between compiled artefacts.
///
/// ## Pattern
///
/// Use cases return `Either<ApplicationFailure, T>` (or
/// `Either<List<ApplicationFailure>, T>` when multiple failures are possible
/// in one pass). Callers pattern-match on the sealed subtype:
///
/// ```dart
/// final result = await loadWorkflow.call(id);
/// result.fold(
///   (failure) => switch (failure) {
///     WorkflowNotFound(:final id) => print('Not found: ${id.fqn}'),
///     UnresolvedImport(:final import) => print('Bad import: ${import.path}'),
///     _ => print('Error: ${failure.message}'),
///   },
///   (unit) => print('Loaded: ${unit.fullyQualifiedName}'),
/// );
/// ```
sealed class ApplicationFailure with EquatableMixin {
  const ApplicationFailure();

  /// A human-readable description of the failure, suitable for logging.
  String get message;
}

// ---------------------------------------------------------------------------
// Repository lookup failures
// ---------------------------------------------------------------------------

/// No [WorkflowCompilationUnit] was found for the requested [id].
///
/// Raised by `LoadWorkflowUseCase` and any other use case that attempts to
/// fetch a workflow compilation unit from the [WorkflowRepository] by FQN.
final class WorkflowNotFound extends ApplicationFailure {
  /// The fully qualified name that was looked up.
  final WorkflowId id;

  const WorkflowNotFound(this.id);

  @override
  String get message => 'Workflow "${id.fqn}" not found in repository.';

  @override
  List<Object?> get props => [id];
}

/// No [CdCompilationUnit] was found for the requested [id].
///
/// Raised by `LoadClassDiagramUseCase` and any use case that explicitly
/// fetches a class diagram by FQN.
final class ClassDiagramNotFound extends ApplicationFailure {
  /// The fully qualified name that was looked up.
  final ClassDiagramId id;

  const ClassDiagramNotFound(this.id);

  @override
  String get message => 'Class diagram "${id.fqn}" not found in repository.';

  @override
  List<Object?> get props => [id];
}

// ---------------------------------------------------------------------------
// Repository collision failures
// ---------------------------------------------------------------------------

/// A [WorkflowCompilationUnit] with the same FQN already exists in the
/// repository.
///
/// Raised by `SaveWorkflowUseCase` when the repository enforces uniqueness
/// and a unit with the same [id] has already been persisted.
final class WorkflowAlreadyExists extends ApplicationFailure {
  /// The FQN of the duplicate.
  final WorkflowId id;

  const WorkflowAlreadyExists(this.id);

  @override
  String get message =>
      'Workflow "${id.fqn}" already exists. Use update instead of save.';

  @override
  List<Object?> get props => [id];
}

/// A [CdCompilationUnit] with the same FQN already exists in the repository.
///
/// Raised by `SaveClassDiagramUseCase` when a class diagram with the same
/// [id] has already been persisted.
final class ClassDiagramAlreadyExists extends ApplicationFailure {
  /// The FQN of the duplicate.
  final ClassDiagramId id;

  const ClassDiagramAlreadyExists(this.id);

  @override
  String get message =>
      'Class diagram "${id.fqn}" already exists. Use update instead of save.';

  @override
  List<Object?> get props => [id];
}

// ---------------------------------------------------------------------------
// Symbol-resolution failures
// ---------------------------------------------------------------------------

/// An `import` statement in a [WorkflowCompilationUnit] could not be matched
/// to any [CdCompilationUnit] in the [ClassDiagramRepository].
///
/// Raised by `ResolveSymbolsUseCase` when one or more of the `import` paths
/// declared at the top of a `.wfm` file has no corresponding compiled class
/// diagram.
///
/// Example source that triggers this:
/// ```
/// import de.monticore.bpmn.cds.MissingDomain.*;
/// ```
final class UnresolvedImport extends ApplicationFailure {
  /// The import statement whose path could not be resolved.
  final ImportStatement import;

  const UnresolvedImport(this.import);

  @override
  String get message =>
      'Import "${import.path}" could not be resolved to any class diagram.';

  @override
  List<Object?> get props => [import];
}

/// A type name referenced inside a [WorkflowCompilationUnit] (in a data
/// object, notification, or operation parameter) could not be matched to any
/// [CdClassifier] in the process's import scope.
///
/// Raised by `ResolveSymbolsUseCase` after all imported class diagrams have
/// been loaded and their type maps merged.
///
/// Example: a `data order:Order;` declaration where `Order` is not exported
/// by any imported class diagram.
final class UnresolvedTypeReference extends ApplicationFailure {
  /// The type name that could not be resolved.
  final String typeName;

  /// The [NodeId] of the workflow element (data object, notification, etc.)
  /// that referenced the unresolved type.
  final NodeId context;

  const UnresolvedTypeReference({
    required this.typeName,
    required this.context,
  });

  @override
  String get message =>
      'Type "$typeName" referenced by "${context.value}" could not be '
      'resolved in the import scope.';

  @override
  List<Object?> get props => [typeName, context];
}

// ---------------------------------------------------------------------------
// Conformance failures
// ---------------------------------------------------------------------------

/// The reference process named in an `<<incarnates="X">>` stereotype could
/// not be found in the [WorkflowRepository].
///
/// Raised by `CheckConformanceUseCase` when the concrete process carries
/// incarnation stereotypes but the reference model they point to is not
/// present in the repository.
final class ReferenceProcessNotFound extends ApplicationFailure {
  /// The name of the reference process (value of the `incarnates` stereotype),
  /// e.g. `"EmployeeOnboarding"`.
  final String referenceProcessName;

  const ReferenceProcessNotFound(this.referenceProcessName);

  @override
  String get message =>
      'Reference process "$referenceProcessName" could not be found. '
      'Ensure the reference model is loaded before checking conformance.';

  @override
  List<Object?> get props => [referenceProcessName];
}
