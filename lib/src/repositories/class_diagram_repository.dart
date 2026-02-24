import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../value_objects/class_diagram_id.dart';

/// The repository contract for persisting and retrieving [CdCompilationUnit]s.
///
/// The application layer defines this interface; the infrastructure layer
/// (e.g. an in-memory store, a file-system store backed by the `.cd` parser,
/// or a remote symbol-table service) implements it.
///
/// ## Why `findByImportPath`?
///
/// [WorkflowCompilationUnit.imports] contains raw import paths such as:
/// ```
/// de.monticore.bpmn.cds.OrderToDelivery.*
/// ```
/// These are *not* necessarily the same as the FQN stored in the repository
/// (the repository key includes the diagram name, e.g.
/// `de.monticore.bpmn.cds.OrderToDelivery`).  [findByImportPath] resolves
/// this by accepting the raw path string from the import statement and
/// returning the best-matching [CdCompilationUnit].
///
/// For a wildcard import `de.foo.Bar.*`, the import path is `de.foo.Bar.*`;
/// implementations should strip the `.*` suffix and match against the
/// diagram-level FQN `de.foo.Bar`.
abstract interface class ClassDiagramRepository {
  /// Returns the [CdCompilationUnit] with the given [id], or [None] if no
  /// unit with that FQN exists.
  TaskEither<Exception, Option<CdCompilationUnit>> findById(ClassDiagramId id);

  /// Resolves an import path (from an [ImportStatement]) to the corresponding
  /// [CdCompilationUnit].
  ///
  /// [importPath] is the raw string from the source file, e.g.
  /// `de.monticore.bpmn.cds.OrderToDelivery.*` or
  /// `de.monticore.bpmn.cds.Domain.DomainUser`.
  ///
  /// Returns [None] if no class diagram can be matched to [importPath].
  TaskEither<Exception, Option<CdCompilationUnit>> findByImportPath(
    String importPath,
  );

  /// Returns the [ClassDiagramId]s of all stored compilation units.
  TaskEither<Exception, List<ClassDiagramId>> findAllIds();

  /// Persists [unit] to the repository (upsert semantics).
  ///
  /// Returns the saved unit unchanged so callers can chain operations.
  TaskEither<Exception, CdCompilationUnit> save(CdCompilationUnit unit);

  /// Removes the unit identified by [id] from the repository.
  ///
  /// No-op if no unit with that [id] exists.
  TaskEither<Exception, Unit> delete(ClassDiagramId id);
}
