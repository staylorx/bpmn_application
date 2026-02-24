import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../value_objects/workflow_id.dart';

/// The repository contract for persisting and retrieving
/// [WorkflowCompilationUnit]s.
///
/// The application layer defines this interface; the infrastructure layer
/// (e.g. an in-memory store, a file-system store backed by the `.wfm` parser,
/// or a remote API) implements it.
///
/// All methods return [TaskEither] — the fpdart type for async operations
/// that can fail — so callers can chain use-case steps monadically without
/// nesting `TaskEither` calls.
///
/// ## Key design decisions
///
/// - Keyed by [WorkflowId] (the FQN of the process).
/// - `save` is an **upsert** — creates or replaces. Use cases that need to
///   distinguish create from update call [findById] first.
/// - `delete` is idempotent — deleting a non-existent ID is not an error.
abstract interface class WorkflowRepository {
  /// Returns the [WorkflowCompilationUnit] with the given [id], or [None] if
  /// no unit with that FQN exists.
  ///
  /// ```dart
  /// repo.findById(id).flatMap(
  ///   (opt) => opt.match(
  ///     () => TaskEither.left(WorkflowNotFound(id)),
  ///     TaskEither.right,
  ///   ),
  /// );
  /// ```
  TaskEither<Exception, Option<WorkflowCompilationUnit>> findById(
    WorkflowId id,
  );

  /// Returns the [WorkflowId]s of all stored compilation units.
  TaskEither<Exception, List<WorkflowId>> findAllIds();

  /// Persists [unit] to the repository (upsert semantics).
  ///
  /// Returns the saved unit unchanged so callers can chain operations.
  TaskEither<Exception, WorkflowCompilationUnit> save(
    WorkflowCompilationUnit unit,
  );

  /// Removes the unit identified by [id] from the repository.
  ///
  /// No-op if no unit with that [id] exists.
  TaskEither<Exception, Unit> delete(WorkflowId id);
}
