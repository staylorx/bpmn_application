import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../failures/application_failure.dart';
import '../repositories/class_diagram_repository.dart';
import '../value_objects/class_diagram_id.dart';

/// Persists a [CdCompilationUnit] to the repository.
///
/// Typically called by the infrastructure (parser) layer after successfully
/// parsing a `.cd` file, or by tooling that programmatically constructs class
/// diagram units.
///
/// ## Save semantics
///
/// The repository uses **upsert** semantics by default.  Set [failIfExists]
/// to `true` to detect and reject duplicate saves.
///
/// ## Returns
///
/// - `Right(unit)` — the unit was saved successfully.
/// - `Left(ClassDiagramAlreadyExists)` — [failIfExists] is `true` and a unit
///   with the same FQN already exists.
///
/// ## Example
///
/// ```dart
/// final useCase = SaveClassDiagramUseCase(repository: repo);
/// final result = await useCase.execute(cdUnit).run();
/// result.fold(
///   (f) => print('Save failed: ${f.message}'),
///   (unit) => print('Saved: ${unit.diagram.name}'),
/// );
/// ```
class SaveClassDiagramUseCase {
  final ClassDiagramRepository _repository;

  const SaveClassDiagramUseCase({required ClassDiagramRepository repository})
    : _repository = repository;

  /// Executes the save.
  ///
  /// [unit] — the class diagram compilation unit to persist.
  /// [failIfExists] — when `true`, returns [ClassDiagramAlreadyExists] if a
  ///   unit with the same FQN already exists instead of overwriting it.
  TaskEither<ApplicationFailure, CdCompilationUnit> execute(
    CdCompilationUnit unit, {
    bool failIfExists = false,
  }) {
    final id = ClassDiagramId(
      unit.package.isRoot
          ? unit.diagram.name
          : '${unit.package}.${unit.diagram.name}',
    );

    if (!failIfExists) {
      return _repository
          .save(unit)
          .mapLeft((e) => ClassDiagramAlreadyExists(id) as ApplicationFailure);
    }

    return _repository
        .findById(id)
        .mapLeft((e) => ClassDiagramNotFound(id) as ApplicationFailure)
        .flatMap(
          (opt) => opt.match(
            () => _repository
                .save(unit)
                .mapLeft(
                  (e) => ClassDiagramAlreadyExists(id) as ApplicationFailure,
                ),
            (_) => TaskEither.left(ClassDiagramAlreadyExists(id)),
          ),
        );
  }
}
